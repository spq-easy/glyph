use 5.0018;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Glyph',
    AUTHOR           => q{Sean P Quinlan <seanq@cpan.org>},
    VERSION_FROM     => 'lib/Glyph.pm',
    ABSTRACT_FROM    => 'lib/Glyph.pm',
    LICENSE          => 'apache_2_0',
    PL_FILES         => { 'bin/install_templates.PL' => '$(INSTALLSCRIPT)' },
    EXE_FILES        => [qw(bin/glyph-add-service)],
    MIN_PERL_VERSION => 5.0018,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'              => 2.000002,
        'Mojolicious'      => 6.43,
        'namespace::clean' => 0.26,
        'YAML::Syck'       => 1.29,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Glyph-*' },
);
