use File::Copy;

system('/usr/bin/java', '-jar', '/usr/picard/picard.jar', 'IntervalListTools', @ARGV);

my $i = 1;
for(glob('*/scattered.interval_list')) {
    #create unique names and relocate all the scattered intervals to a single directory
    File::Copy::move($_, qq{$i.interval_list});
    $i++
}