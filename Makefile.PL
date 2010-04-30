use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'pai',
    VERSION_FROM      => 'scripts/pai', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
        'Regexp::Grammars'  => 0,
        'Getopt::Euclid'    => 0,
        'Data::Dumper'      => 0,
        'List::Util'        => 0,
        'File::Temp'        => 0,
        'Readonly'          => 0,
        },
    EXE_FILES => [qw(scripts/pai)],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'scripts/pai', # retrieve abstract from module
       AUTHOR         => 'Bryan Matsuo <bryan.matsuo@gmail.com>') : ()),
);
