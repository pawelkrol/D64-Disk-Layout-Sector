#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use File::Find;
use FindBin qw($Bin);
use Getopt::Long;

my $help;
my $dry_run;
my $new_version;
my $release_date = DateTime->now->ymd;

GetOptions(
    'dry-run'   => \$dry_run,
    'help'      => \$help,
    'version=s' => \$new_version,
);

help() if $help or not defined $new_version or $new_version !~ m/^\d+\.\d+$/;

print <<DETAILS;

Updating version number and release date of the D64::Disk::Layout::Sector package:

  * new version number: $new_version
  * new release date: $release_date

DETAILS

my $command = sprintf q{grep -e '%s  [0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}' Changes | wc -l}, $new_version;
my $result = `$command`;

die qq{FATAL ERROR! Version number "${new_version}" missing from the "Changes" file (please update it listing all the changes first before running this script).\n\n} if $result != 1;

$command = sprintf q{sed -i -e "s/%s  [0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}/%s  %s/" Changes}, $new_version, $new_version, $release_date;

print "$command\n";
system $command unless $dry_run;

$command = sprintf q{sed -i -e "s/D64::Disk::Layout::Sector Version [0-9]\\+\\.[0-9]\\+/D64::Disk::Layout::Sector Version %s/" README}, $new_version;

print "$command\n";
system $command unless $dry_run;

## TODO: Simplify by replacing "finddepth" with the list of files fetched from the "MANIFEST"
finddepth({no_chdir => 0, preprocess => \&skip_git, wanted => \&bump_version},  "${Bin}/..");

print "\n";

sub skip_git {
    my @names = @_;

    return grep { $_ ne '.git' } @names;
}

sub bump_version {
    my $filename = $_;

    return unless -f $filename;

    my $command = sprintf q{sed -i -e "s/our \\$VERSION = '[0-9]\\+\\.[0-9]\\+';/our \\$VERSION = '%s';/" %s}, $new_version, $filename;

    print "$command\n";
    system $command unless $dry_run;

    $command = sprintf q{sed -i -e "s/Version [0-9]\\+\\.[0-9]\\+ ([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\})/Version %s (%s)/" %s}, $new_version, $release_date, $filename;

    print "$command\n";
    system $command unless $dry_run;
}

sub help {
    print <<USAGE;

Usage: $0 <OPTIONS>

    --dry-run          - show what would be done without performing any actions
    --version=<NUMBER> - set (mandatory) version number
    --help             - show this help message

USAGE

    exit;
}
