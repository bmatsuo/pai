# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl pai.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('App::Pai::AlsaState') };
BEGIN { use_ok('App::Pai::AlsaState::Parser') };

#########################

# Create a typical alsa state
my $state_1 =<<EOSTATE;
state.Intel {
	control.1 {
		comment.access 'read write'
		comment.type BOOLEAN
		comment.count 2
		iface MIXER
		name 'Speaker Playback Switch'
		value.0 true
		value.1 true
	}
	control.2 {
		comment.access 'read write'
		comment.type INTEGER
		comment.count 2
		comment.range '0 - 64'
		comment.dbmin -6300
		comment.dbmax 100
		iface MIXER
		name 'Speaker Playback Volume'
		value.0 63
		value.1 63
	}
	control.3 {
		comment.access 'read write'
		comment.type BOOLEAN
		comment.count 2
		iface MIXER
		name 'Headphone Playback Switch'
		value.0 true
		value.1 true
	}
	control.4 {
		comment.access 'read write'
		comment.type INTEGER
		comment.count 2
		comment.range '0 - 64'
		comment.dbmin -6300
		comment.dbmax 100
		iface MIXER
		name 'Headphone Playback Volume'
		value.0 63
		value.1 63
	}
	control.5 {
		comment.access 'read write'
		comment.type INTEGER
		comment.count 2
		comment.range '0 - 46'
		comment.dbmin -1700
		comment.dbmax 2900
		iface MIXER
		name 'Capture Volume'
		value.0 46
		value.1 46
	}
	control.6 {
		comment.access 'read write'
		comment.type BOOLEAN
		comment.count 2
		iface MIXER
		name 'Capture Switch'
		value.0 true
		value.1 true
	}
	control.7 {
		comment.access 'read write'
		comment.type INTEGER
		comment.count 2
		comment.range '0 - 3'
		comment.dbmin 0
		comment.dbmax 3000
		iface MIXER
		name 'Mic Boost'
		value.0 0
		value.1 0
	}
	control.8 {
		comment.access 'read write'
		comment.type INTEGER
		comment.count 2
		comment.range '0 - 31'
		comment.dbmin -3450
		comment.dbmax 1200
		iface MIXER
		name 'Beep Playback Volume'
		value.0 0
		value.1 0
	}
	control.9 {
		comment.access 'read write'
		comment.type BOOLEAN
		comment.count 2
		iface MIXER
		name 'Beep Playback Switch'
		value.0 false
		value.1 false
	}
	control.10 {
		comment.access 'read write'
		comment.type INTEGER
		comment.count 1
		comment.range '0 - 64'
		comment.dbmin -6400
		comment.dbmax 0
		iface MIXER
		name 'Master Playback Volume'
		value 51
	}
	control.11 {
		comment.access 'read write'
		comment.type BOOLEAN
		comment.count 1
		iface MIXER
		name 'Master Playback Switch'
		value true
	}
	control.12 {
		comment.access 'read write user'
		comment.type INTEGER
		comment.count 2
		comment.range '0 - 255'
		comment.tlv '0000000100000008ffffec1400000014'
		comment.dbmin -5100
		comment.dbmax 0
        iface MIXER
		name 'PCM Playback Volume'
		value.0 255
		value.1 255
	}
}
EOSTATE
# End of the 'typical' state output

my $alsa_state_1 = eval {App::Pai::AlsaState::Parser->parse($state_1)};

ok(!$@, "parse a 'typical' state");

App::Pai::AlsaState->control_toggle(
    App::Pai::AlsaState->find_control_named(
        App::Pai::AlsaState->control_name(
            'master', 
            'switch'), 
        $alsa_state_1));
my $boolean 
    = App::Pai::AlsaState->control_switch(
        App::Pai::AlsaState->find_control_named(
            App::Pai::AlsaState->control_name(
                'master', 
                'switch'), 
            $alsa_state_1), );
ok($boolean eq 'false');
$boolean 
    = App::Pai::AlsaState->control_switch(
        App::Pai::AlsaState->find_control_named(
            App::Pai::AlsaState->control_name(
                'master', 
                'switch'), 
            $alsa_state_1), 
        'true');
ok($boolean eq 'true');

1;
