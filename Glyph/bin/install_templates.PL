#!/usr/bin/env perl

use warnings;
use strict;

use feature qw(say);
use Data::Dumper;
use File::Path qw(make_path);
use File::Copy::Recursive qw(dircopy);
use FindBin qw($Bin);

my $orig = "$Bin/../templates";
my $new  = "$ARGV[0]/glyph-templates";

dircopy($orig, $new);
