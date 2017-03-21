use feature qw(say);

for my $line (<>) {
    chomp $line;

    next if substr($line,0,1) eq '@'; #skip header lines

    my ($chrom, $start, $stop) = split(/\t/, $line);
    say(join("\t", $chrom, $start-1, $stop));
}
