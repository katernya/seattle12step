require RecoveryAlphabet::Geo::Places;

%cities = (#'Seattle' => 1,
	   'Mtlk Terr' => 'Mountlake Terrace',
	   'Lk Forest Pk' => 'Lake Forest Park',
	   'Lynwd' => 'Lynnwood',
	   #'Shoreline', 'Edmonds', 'Lynnwood', 'Mountlake Terrace', 'SeaTac', 'Vashon', 'Burien', 'Renton', 'Kent', 'Auburn', 'Maple Valley', 'Enumclaw', 'Federal Way', 'Covington',
	   'B\'vue' => 'Bellevue',
	   #'Bothell', 'Kirkland', 'Issaquah', 'Snoqualmie', 'Redmond', 'Duvall',
	   'N Bend' => 'North Bend',
	   #'Hunts Point', 'Mercer Island', 'Preston', 'Clyde Hill', 'Tukwila', 'Black Diamond',
	   'Snoq' => 'Snoqualmie',
# 'Bellevue',
	   'Wdnville' => 'Woodinville',
	   'Samm\\.' => 'Sammamish',
# 'Fall City', 'Kenmore', 'Medina', 'Mukilteo',
	   'Blk Dia' => 'Black Diamond',
#'Tacoma',
	   'Fed Wy' => 'Federal Way',
	   'DesMoines' => 'Des Moines',
#, 'Snohomish'
	   'Mtlke Terrace' => 'Mountlake Terrace',
	   #, 'Riverton', 'Hobart', 'Sammamish', 'Woodinville', 'Carnation', 'Morgan', 'North Bend',
	   'Blk Dia\\.' => 'Black Diamond',
#, 'Snoqualmie Pass'
);

sub parseaddress {
    my $add = shift @_;
    $add =~ s!\(.*\)!!s;
    my $rgxp = join("|",keys %::cities);
$add =~ s/($rgxp)/$::cities{$1}/ge;
    my $zip;
    print STDERR $add, "\n";
    if($add =~ s!(\D{3})(98\d\d\d)!\1!)
      {
	$zip = $2;
      }

    if($add =~ /(\d+)(?:-|\s+)(?:(N|E|S|W|NE|NW|SE|SW)\.?\s+)?(\S+(?:\s+\S{4,})?)(?:\s+(St|Street|Wy|Way|Ave|Avenue|Dr|Drive|Hwy|Highway|Blvd|rd|Road))?(?:\s+(NE|NW|SE|SW|N|E|S|W)\.?)?/i)
{
    ([$1, $2, $3, $4, $5], $city, $zip);
}
else
{
    undef;
}
}
1;
