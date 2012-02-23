use JSON;
use DB_File;
use Time::Local;
my $json = new JSON;

my(%hash);
my $hasho = tie(%hash, DB_File, "placecache.db", O_RDONLY);
die unless $hasho;
print join("\t", qw(InputLocation ResultIndex RequestTime InputGeoLocation InputRadius InputName ResultTypes ResultName ResultVicinity)), "\n";
while(($key, $valjson) = each %hash)
{
    my $val = decode_json($valjson);
    my $rsp = $val->{Response};
    my $in = $val->{Input};
    my(@r) = @{$rsp->{results}};
    for(my $i = 0; $i < $#r; $i++)
    {
	my $r = $r[$i];
	print join("\t", $key, $i, scalar(localtime($val->{RequestTime})), $in->{location}, $in->{radius}, $in->{name}, join(" ", @{$r->{types}}), $r->{name}, $r->{vicinity}), "\n";
}
}

print $json->pretty->encode(\%dump);
