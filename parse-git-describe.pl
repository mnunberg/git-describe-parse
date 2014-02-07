#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $rv = GetOptions(
    'basetag|t' => \my $PrintBase,
    'ncommits|n' => \my $PrintCount,
    'sha|s' => \my $PrintSHA,
    'force|f' => \my $Force,
    'help|h' => \my $WantHelp);

my $HELPTEXT =
<<EOF;
    -t --basetag    Print base tag
    -n --ncommits   Print number of commits since base
    -s --sha        Print abbreviated SHA1
    -f --force      Always print ncommits/sha, even if HEAD is a tag
EOF

if (!$rv) {
    print $HELPTEXT;
    exit(1);
}
if ($WantHelp) {
    print $HELPTEXT;
    exit(0);
}

my $output = qx(git describe --long);
$output =~ s/\s+$//g;
$output =~ s/^\s+//g;

my @components = split('-', $output);
my $sha = pop @components;
my $ncommits = pop @components;
my $version = join('-', @components);

if ($PrintBase) {
    print "$version\n";
}

if (!$Force) {
    $Force = int($ncommits);
}

if ($PrintSHA && $Force) {
    print "$sha\n";
}

if ($PrintCount && $Force) {
    print "$ncommits\n";
}
