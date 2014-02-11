#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Time::gmtime;

my $rv = GetOptions(
    'input|I=s' => \my $Input,
    'tag|basetag|t' => \my $PrintBase,
    'version|v' => \my $PrintVersion,
    'pre-release|P' => \my $PrintPTag,
    'ncommits|n' => \my $PrintCount,
    'sha|s' => \my $PrintSHA,
    'force|f' => \my $Force,
    'rpm' => \my $RPM,
    'deb' => \my $DEB,
    'tar' => \my $TAR,
    'help|h' => \my $WantHelp);

my $HELPTEXT =
<<EOF;
    -I --input      Input (instead of git exe, for testing)
    -t --basetag    Print base tag (i.e. x.y.z-foo)
    -n --ncommits   Print number of commits since base
    -s --sha        Print abbreviated SHA1
    -f --force      Always print ncommits/sha, even if HEAD is a tag
    -v --version    Print base x.y.z version
    -P --pre-release Print prerelease tag, e.g. 'beta'
       --deb        Print proper "Debian" version number
       --rpm        Print proper "RPM" version number
       --tar        Print proper "Tarball" name
EOF

if (!$rv) {
    print $HELPTEXT;
    exit(1);
}
if ($WantHelp) {
    print $HELPTEXT;
    exit(0);
}

my $output;
if (!$Input) {
    $output = qx(git describe --long);
} else {
    $output = $Input;
}
$output =~ s/\s+$//g;
$output =~ s/^\s+//g;

my @components = split('-', $output);
my $sha = pop @components;
my $ncommits = pop @components;
my $version = join('-', @components);
my ($v_maj, $v_min, $v_patch, $extras) =
    ($version =~ m/(\d+)\.(\d+)\.(\d+)(-(.+))?/);

my $xyz_version = join('.', $v_maj, $v_min, $v_patch);
if ($extras) {
    # Strip leading '-' from extras
    $extras =~ s/^[+-]+//g;
}

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

if ($PrintPTag) {
    print "$extras\n";
}

if ($PrintVersion) {
    printf("%d.%d.%d\n", $v_maj, $v_min, $v_patch);
}

if ($DEB) {
    my $vbase = $xyz_version;
    if ($ncommits || $extras) {
        $vbase .= "~";
    }
    if ($ncommits) {
        $vbase .= "r$ncommits+$sha";
    }
    if ($extras) {
        if ($ncommits) {
            $vbase .= "~";
        }
        $vbase .= $extras;
    }
    print "$vbase\n";
}

if ($RPM) {
    my $vbase = $xyz_version;

    # Figure out the release tag.
    # If we're a pre-release AND a snapshot, then the build number goes at the end.
    # Otherwise,
    my $relno;

    if ($extras) {
        $relno = 0;
    } else {
        if (!$ncommits) {
            $relno = 1;
        } else {
            $relno = $ncommits + 1;
        }
    }

    $vbase .= "-$relno";

    # Pre-release, no commits
    if ($extras) {
        if ($ncommits) {
            $vbase .= ".r${ncommits}GIT${sha}";
        } else {
            $vbase .= ".0";
        }
        $vbase .= ".$extras";
    } elsif ($ncommits) {
        # No extras. Do we still have something here?
        $vbase .= ".r${ncommits}GIT${sha}.SP";
    }
    print "$vbase\n";
}

if ($TAR) {
    my $copy = $output;
    $copy =~ s/-/_/g;
    print "$copy\n";
}
