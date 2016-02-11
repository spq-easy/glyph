#!perl -T
use 5.0018;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Glyph' ) || print "Bail out!\n";
}

diag( "Testing Glyph $Glyph::VERSION, Perl $], $^X" );
