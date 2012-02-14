use JSON;
use DB_File;
my $geocache = tie(%geocache, DB_File, "geocache2.db", O_CREAT|O_RDWR, 0640, $DB_HASH);
die unless $geocache;
while(($key, $val) = each %geocache)
{
    $dump{geocache}{$key} = decode_json($val);
}


my $placecache = tie(%placecache, DB_File, "placecache.db", O_CREAT|O_RDWR, 0640, $DB_HASH);
die unless $placecache;
while(($key, $val) = each %placecache)
{
    $dump{placecache}{$key} = decode_json($val);
}
my $json = JSON->new->allow_nonref;
print $json->pretty->encode(\%dump);
