use JSON;
use DB_File;
my $json = new JSON;
my(@dbs) = @ARGV;
unless(scalar(@dbs))
{
    @dbs = qw(placecache geocache2);
}

foreach my $db (@ARGV)
{
    my(%hash);
    my $hasho = tie(%hash, DB_File, "$db.db", O_RDONLY);
    die unless $hasho;
    while(($key, $val) = each %hash)
    {
	$dump{$db}{$key} = decode_json($val);
    }
}
print $json->pretty->encode(\%dump);
