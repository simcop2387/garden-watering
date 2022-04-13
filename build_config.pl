#!/usr/bin/env perl

use strict;
use warnings;
use Path::Tiny;

my $out_file=path("garden-water.yml");

$out_file->spew_utf8("test");
