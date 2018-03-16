#!/usr/bin/perl

use strict;
use warnings;

use feature qw(say);

die("Wrong number of arguments. Provide docm_vcf, normal_sample_name, tumor_sample_name, output_dir") unless scalar(@ARGV) == 4;
my ($docm_out_vcf, $normal_name, $tumor_name, $outdir) = @ARGV;

open(my $docm_vcf_fh, $docm_out_vcf)
    or die("couldn't open $docm_out_vcf to read");
open(my $docm_filter_fh, ">", "$outdir/docm_filter_out.vcf")
    or die("couldn't open docm_filter_out.vcf for write");

my ($normal_index, $tumor_index);

while (<$docm_vcf_fh>) {
    chomp;
    if (/^##/) {
        say $docm_filter_fh $_;
    }
    elsif (/^#CHROM/) {
        my @columns = split /\t/, $_;
        my %index = (
            $columns[9]  => 9,
            $columns[10] => 10,
        );
        ($normal_index, $tumor_index) = map{$index{$_}}($normal_name, $tumor_name);
        unless ($normal_index and $tumor_index) {
            die "Failed to get normal_index: $normal_index for $normal_name and tumor_index: $tumor_index for $tumor_name";
        }
        $columns[9]  = 'NORMAL';
        $columns[10] = 'TUMOR';
        my $header = join "\t", @columns;
        say $docm_filter_fh $header;
    }
    else {
        my @columns = split /\t/, $_;
        my @tumor_info = split /:/, $columns[$tumor_index];
        my ($AD, $DP) = ($tumor_info[1], $tumor_info[2]);
        next unless $AD;
        my @AD = split /,/, $AD;
        shift @AD; #the first one is ref count
        for my $ad (@AD) {
            if ($ad > 5 and $ad/$DP > 0.01) {
                $columns[9]  = $columns[$normal_index];
                $columns[10] = $columns[$tumor_index];
                my $new_line = join "\t", @columns;
                say $docm_filter_fh $new_line;
                last;
            }
        }
    }
}

close($docm_vcf_fh);
close($docm_filter_fh);
