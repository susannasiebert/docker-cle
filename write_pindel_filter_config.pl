use feature qw(say);

die("wrong number of arguments") unless scalar(@ARGV) == 3;
my ($output_summary, $reference, $outdir) = @ARGV;

open(my $config_fh, ">", "$outdir/filter.config")
    or die("couldn't open file");

say $config_fh "input=$output_summary";
say $config_fh "vaf=0.1";
say $config_fh "cov=20";
say $config_fh "hom=6";
say $config_fh "pindel2vcf=/usr/bin/pindel2vcf";
say $config_fh "reference=$reference";
say $config_fh "referencename=GRCh38DH"; #FIXME should match reference
say $config_fh "referencename=20161216";
say $config_fh "output=$outdir/pindel.out.vcf";

close($config_fh);