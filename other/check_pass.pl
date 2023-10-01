#!/usr/bin/env perl

use warnings;
use strict;

my @pwent = getpwnam($ARGV[0]);
if (!@pwent) {die "Invalid username: $ARGV[0]\n";}

my $supplied = <STDIN>;
chomp($supplied);

if (crypt($supplied, $pwent[1]) eq $pwent[1]) {
    print STDERR "Good, valid password for $ARGV[0]\n";
    exit(0);
} else {
    print STDERR "Wrong (INVALID!) password for $ARGV[0]\n";
    exit(1);
}
