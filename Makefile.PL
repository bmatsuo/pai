use 5.010000;
use inc::Module::Install;
  
# Define metadata
name            'pai';
author_from     'scripts/pai';
abstract_from   'scripts/pai';
version_from    'scripts/pai';
license         'Perl';

# Specific dependencies
requires        'Regexp::Grammars'  => 0;
requires        'Getopt::Euclid'    => 0;
requires        'Data::Dumper'      => 0;
requires        'List::Util'        => 0;
requires        'File::Temp'        => 0;
requires        'Readonly'          => 0;
test_requires  'Test::More'  => '0';
requires_external_bin   'alsactl';
install_script 'scripts/pai';

WriteAll;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#WriteMakefile(
#    NAME              => 'pai',
#    VERSION_FROM      => 'scripts/pai', # finds $VERSION
#    PREREQ_PM         => { # e.g., Module::Name => 1.1
#        'Regexp::Grammars'  => 0,
#        'Getopt::Euclid'    => 0,
#        'Data::Dumper'      => 0,
#        'List::Util'        => 0,
#        'File::Temp'        => 0,
#        'Readonly'          => 0,
#        },
#    EXE_FILES => [qw(scripts/pai)],
#    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
#      (ABSTRACT_FROM  => 'scripts/pai', # retrieve abstract from module
#       AUTHOR         => 'Bryan Matsuo <bryan.matsuo@gmail.com>') : ()),
#);
