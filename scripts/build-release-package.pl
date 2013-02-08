#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Copy;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Getopt::Long;


my $help;
my $output_dir;
my $manifest_file = 'MANIFEST';
my $package_name  = 'D64-Disk-Layout-Sector';
my $version_from  = 'Sector.pm';

GetOptions(
    'help'         => \$help,
    'output-dir=s' => \$output_dir,
);

help() if $help or not defined $output_dir or not -d $output_dir;

my $version_number = get_version_number($version_from);
my $project_dir = sprintf '%s-%s', $package_name, $version_number;
my $target_file = sprintf '%s/%s.tar.gz', $output_dir, $project_dir;

die "File already exists: $target_file" if -e $target_file;

print <<DETAILS;

Building a new release package of "$package_name" project:

  * version number: $version_number
  * target file: $target_file

DETAILS

my $temp_dir = tempdir(CLEANUP => 1);

my $build_dir = setup_build_dir($temp_dir, $project_dir, $manifest_file);

compress_files($build_dir, $project_dir, $target_file);

print "\nBuild successful!\n\n";

sub get_version_number {
    my ($version_from) = @_;

    my $command = sprintf q{grep -e 'our $VERSION' %s | awk '{print $4}' | sed -e "s/[';]//g"}, $version_from;

    my $version_number = `$command`;
    chomp $version_number;

    return $version_number;
}

sub setup_build_dir {
    my ($temp_dir, $project_dir, $manifest_file) = @_;

    my $build_dir = sprintf '%s/%s', $temp_dir, $project_dir;

    mkdir $build_dir;

    my $manifest = `cat $manifest_file`;
    $manifest =~ s/\r\n/\n/g;

    print "Copying files:\n";

    my @filelist = split "\n", $manifest;
    for my $file (@filelist) {

        my $source = sprintf '%s/../%s', $Bin, $file;
        my $target = sprintf '%s/%s', $build_dir, $file;

        (my $target_path = $target) =~ s!/[^/]+$!!;
        make_path($target_path, { verbose => 0, mode => 0755 });

        printf "\n  * from: %s", $source;
        printf "\n      to: %s\n", $target;

        copy($source, $target) or die "\nCopy failed: $!";
    }

    return $build_dir;
}

sub compress_files {
    my ($build_dir, $project_dir, $target_file) = @_;

    printf qq{\nCompressing project build into "tar.gz" archive:\n\n  * target file: %s\n\n}, $target_file;

    my $dir = getcwd;
    chdir "$build_dir/..";

    my $command = sprintf 'tar czf %s %s', $target_file, $project_dir;
    print "    $command\n";
    system $command;

    chdir $dir;

    return;
}

sub help {
    print <<USAGE;

Usage: $0 <OPTIONS>

    --output-dir=<DIRECTORY> - set (mandatory) output directory
    --help                   - show this help message

USAGE

    exit;
}
