use JSON;
use DB_File;
my $json = JSON->new->allow_nonref;
my $geocache = tie(%geocache, DB_File, "geocache2.db", O_CREAT|O_RDWR|O_TRUNC, 0640, $DB_HASH);
die unless $geocache;

my $dump = decode_json(join('', <>));
while(($key, $val) = each %{$dump->{geocache}})
{
    $geocache{$key} = $json->pretty->encode($val);
}


my $placecache = tie(%placecache, DB_File, "placecache.db", O_CREAT|O_RDWR|O_TRUNC, 0640, $DB_HASH);
die unless $placecache;
while(($key, $val) = each %{$dump->{placecache}})
{
    $placecache{$key} = $json->pretty->encode($val);
}
