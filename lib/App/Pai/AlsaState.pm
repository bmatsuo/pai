#!/usr/bin/env perl
package App::Pai::AlsaState;

use App::Pai::AlsaState::Parser;
use POSIX qw{ceil};

use Carp;

my %control_names = (
    'headphone' 
        => {
            'switch' => 'Headphone Playback Switch', 
            'volume' => 'Headphone Playback Volume',
        },
    'speaker'
        => {
            'switch' => 'Speaker Playback Switch', 
            'volume' => 'Speaker Playback Volume',
        },
    'master'
        => {
            'switch' => 'Master Playback Switch', 
            'volume' => 'Master Playback Volume',
        },
    'PCM'
        => {
            'volume' => 'PCM Playback Volume',
        },
    'mic'
        => {
            'switch' => 'Capture Switch', 
            'volume' => 'Capture Volume',
            'boost' => 'Mic Boost',
        },
    'beep'
        => {
            'switch' => 'Beep Playback Switch', 
            'volume' => 'Beep Playback Volume',
        },
);

# Subroutine: control_name($connection, $type)
# Type: INTERFACE SUB
# Purpose: 
#   Lookup specific connection controller names with simpler labels.
# Returns: 
#   Name of the $type (switch/volume/...) controller for $connection
#   (speaker/headphone/...).
sub control_name {
    my ($class,$connection, $type) = @_;

    my $control_name_ref = $control_names{$connection};


    croak("Couldn't find connection  $connection") 
        if !defined $control_name_ref;

    my $control = $control_name_ref->{$type};

    croak("Couldn't find control $connection/$type") 
        if !defined $control;

    return $control;
}

# Subroutine: state_string($state)
# Type: INTERFACE SUB 
# Purpose: 
#   Format an object with structure as returned by parse_alsa_state as a
#   valid alsa state configuration file that can be parsed by alsactl. 
#   This is how modified settings will be loaded.
# Returns: 
#   The formatted alsa state string.
sub state_string {
    my ($state) = @_;

    my $state_str = "state.Intel {\n";

    # Add the controls
    for my $control (@{$state->{'controls'}}) {
        $state_str .= "\tcontrol.$control->{'id'} {\n";

        for my $comment (@{$control->{'comments'}}) {
            $state_str 
                .= "\t\tcomment.$comment->{'ctype'} $comment->{'value'}\n";
        }

        $state_str .= "\t\tiface $control->{'interface'}\n";

        $state_str .= "\t\tname $control->{'name'}\n";

        for my $value (@{$control->{'values'}}) {
            $state_str .= "\t\tvalue";

            $state_str .= ".$value->{'id'}" if defined $value->{'id'};

            $state_str .= " $value->{'data'}\n";
        }

        $state_str .= "\t}\n";
    }

    $state_str .= "}\n";
    return $state_str
}


# Subroutine: _alsactl_cmd($action, $card)
# Type: INTERNAL UTILITY
# Purpose: 
#   Create a command to start alsactl
# Returns: 
#   Command as a list.
sub _alsactl_cmd {
    my ($action, $card) = @_;

    my @cmd = ('alsactl', '-f', '-', $action);

    push @cmd, $card if !defined $card && $card !~ m/\A\z/xms;

    return @cmd;
}

# Subroutine: commit($state, $card)
# Type: INTERFACE SUB
# Purpose: 
#   Commit an alsa state by giving to alsactl.
# Returns: 
#   undef
sub commit {
    my ($class, $state, $card) = @_;

    my @alsactl_cmd = _alsactl_cmd('restore', $card);

    my $state_str = state_string($state);

    open my $alsactl, "|-", @alsactl_cmd
        or croak("Couldn't open alsa to restore settings.\n");

    print {$alsactl} $state_str;

    close $alsactl;

    return;
}

# Subroutine:   get(file => undef, card => undef)
# Type: INTERFACE SUB
# Purpose: 
#   Read and parse the alsa state either from a file or by querying alsa.
# Arguments:    file => Path to alsa state config 
#                           (alsactl queried if undef)
#               card => Card #, ID, or device path
#                           (all returned if undef)
# Returns: 
#   The result of App::Pai::AlsaState::Parser->parse() on the raw 
#   string of the requested alsa state.
sub get { 
    return App::Pai::AlsaState::Parser->parse(get_raw(@_)); }

# Subroutine: get_raw(filename => undef, card => undef)
# Type: INTERNAL SUB
# Purpose: 
#   Read in an alsa state file, or query alsactl for it's current state.
# Arguments:    file => Path to alsa state config 
#                           (alsactl queried if undef)
#               card => Card #, ID, or device path
#                           (all returned if undef)
# Returns: 
#   The configuration as a single string (with newlines '\n').
sub get_raw {
    my ($class, %option) = @_;

    my $filename = $option{file};
    my $card = $option{card};

    my $state_fh;

    # If not given a filename, then we need to get alsa's current info.
    if (!defined $filename) {
        # Create the alsactl query command.
        my @alsactl_call = _alsactl_cmd("store", $card);

        # Open a pipe from alsa.
        open $state_fh, '-|', @alsactl_call
            or croak("Couldn't run: ". join(q{ }, @alsactl_call)."\n");
    } else {
        # Open the alsa state file.
        open $state_fh, "<", $filename 
            or croak("Can't open alsa state file at '$filename'.\n");
    }

    # Slurp up the state contents.
    my $state = do {local $/; <$state_fh>};

    # Close the state file.
    close $state_fh;

    return $state;
}

# Subroutine: find_control_named($name, $alsa_state)
# Type: INTERFACE SUB
# Purpose: 
#   Look through $alsa_state for the control with name equal to $name.
# Returns: 
#   Refenence to control named $name.
sub find_control_named {
    my ($class, $name, $alsa_state) = @_;

    croak("find_contol_named(): name not given\n") 
        if !defined $name;

    croak("find_control_named(): alsa_state is not defined\n") 
        if !defined $alsa_state;

    my ($control) 
        = grep {$_->{'name'} eq qq{'$name'}} @{$alsa_state->{'controls'}};

    croak("Couldn't find control named $name in control list.\n") 
        if !defined $control;

    return $control;
}

# Subroutine: _is_valid_level($level)
# Type: INTERNAL UTILITY
# Purpose: 
#   Check that a volume level is valid.
# Returns: 
#   True boolean value if $level is in interval [0,1];
#   false otherwise.
sub _is_valid_level {
    my ($level) = @_;

    return 0 <= $level && $level <= 1;
}

# Subroutine: control_toggle($control)
# Type: INTERFACE SUB
# Purpose: 
#   Toggle the boolean value of $control.
# Returns: 
#   The new value of the control.
sub control_toggle {
    my ($class, $control) = @_;

    my $boolean = control_switch($control);

    return 
        control_switch(
            $control, 
            $boolean =~ m/\Atrue\z/xms ? 'true' : 'false');
}

# Subroutine:   control_switch($control, $boolean)
#               control_switch($control)
# Type: INTERFACE SUB
# Purpose: 
#   Set the value of a control toggle switch if given a boolean value.
#   Boolean values must be 'true' or 'false'
# Returns: 
#   'true' or 'false'
sub control_switch {
    my ($class, $control, $boolean) = @_;

    my $name =  $control->{'name'};

    croak("$boolean is not 'true' or 'false'.\n")
        if (defined $boolean && $boolean !~ m/\Atrue|false\z/xms);
    

    croak("control $name does not accept boolean values.\n")
        if (! $control->{'type'} eq 'BOOLEAN' );

    if (!defined $boolean) {
        for my $value (@{$control->{'values'}}) {
            $value->{'data'} = $boolean;
        }
        return $boolean;
    }

    return map {$_->{'data'}} @{$control->{'values'}};
}

# Subroutine:   control_level($control, $level)
#               control_level($control)
# Type: INTERFACE SUB
# Purpose: 
#   Adjust the volume level of a control if given levels.
#   Levels are percentages. The actual value assigned will 
#   be the ceiling of the percentage value.
#   TODO: Allow changing of left and right level separately.
# Returns: 
#   The level of the control.
sub control_level {
    my ($class, $control, $level) = @_;

    my $name =  $control->{'name'};

    if (defined $level && !_is_valid_level($level) ) {
        croak("level $level of out bounds [0,1].\n");
    }

    if (! $control->{'type'} eq 'INTEGER' ) {
        croak("control $name does not accept integer values.\n")
    }

    if (defined $level) {
        my ($min,$max);

        for my $comment (@{$control->{'comments'}}) {
            if ($comment->{'ctype'} eq 'range') {
                $comment->{'value'} =~ m/'(\d+) \s* - \s* (\d+)'/xms;
                ($min, $max) = ($1, $2);
            }
        }

        if (!defined $min || !defined $max) {
            croak("can't find range of control $name.\n")
        }

        my $new_level = ceil($min + $level * ($max - $min));

        #print "setting values to $new_level\n";
        for my $value (@{$control->{'values'}}) {
            $value->{'data'} = $new_level;
        }

        return $new_level;
    }

    return map {$_->{'data'}} @{$control->{'values'}};
}

return 1
