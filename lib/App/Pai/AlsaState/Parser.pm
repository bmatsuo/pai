package App::Pai::AlsaState::Parser;

use Carp;

use Regexp::Grammars;
use Data::Dumper;

use Exception::Class ('ParseException');

my $alsa_state_parser = qr{
    (?: 
        <.ws><State><.ws>
    )
    #####################
    # LANGUAGE TOKENS
    #####################
    <token: ws>         (?:\s+|\n+)*
    <token: dot>        \.
    <token: POSINT>     \d+
    <token: INT>        -?<.POSINT>
    <token: STRING>     '[^']+'
    <token: ID> <.dot>  <MATCH=POSINT>
    <token: DATATYPE>   BOOLEAN | INTEGER
    <token: CVALUE>     <MATCH=DATATYPE> | <MATCH=ID> 
                        | <MATCH=STRING> | <MATCH=INT>
    <token: CTYPE>      <.dot><MATCH=(?:[a-z]+)>
    <token: DATA>       true | false | <MATCH=POSINT>
    <token: CARD>       <.dot><MATCH=(?:[A-Z][a-z]+)>
    <token: STATE>      state
    <token: CONTROL>    control
    <token: COMMENT>    comment
    <token: INTERFACE>  iface
    <token: NAME>       name
    <token: VALUE>      value
    ######################
    # GRAMMAR PRODUCTIONS
    ######################
    <rule: State>
        <type=STATE>(<card=CARD>) \{ <[controls=Control]>+ \} 
    <rule: Control>
        <type=CONTROL>(<id=ID>) \{
            <[comments=Comment]>+
            <interface=Interface>
            <name=Name>
            <[values=Value]>*
        \}
    <rule: Comment>
        <type=COMMENT><ctype=CTYPE> <value=CVALUE>
    <rule: Interface>
        <type=INTERFACE> <MATCH=([A-Z]+)>
    <rule: Name>
        <type=NAME> <MATCH=STRING>
    <rule: Value>
        <type=VALUE><id=ID>?  <data=DATA>
}x;

sub _remove_empty_keys {
    my ($hash_ref) = @_;

    if (ref $hash_ref eq 'ARRAY') {
        for my $item_ref (@$hash_ref) {
            _remove_empty_keys($item_ref);
        }
    } 
    elsif (ref $hash_ref eq 'HASH') { 
        # Delete the value keyed by the empty sting (the matched string).
        delete $hash_ref->{q{}};

        # Call recursively on other hash values.
        for my $key (keys %$hash_ref) {
            my $value_ref = $hash_ref->{$key};
            _remove_empty_keys($value_ref);
        }
    }

    return;
}

sub parse {
    my ($class, $alsa_state_string) = @_;

    if ($alsa_state_string =~ $alsa_state_parser) {
        my $alsa_state = $/{"State"};
        _remove_empty_keys($alsa_state);
        return $alsa_state;
    } else {
        croak(ParseException->new("Error parsing state."));
    }
}
