#!/usr/bin/perl


use Math::Trig;

open(OUTPUT, ">meetings-out.txt");

open(UPDATES, "updates.txt");
chomp($uf = scalar(<UPDATES>));
@uf = split(/\t/, $uf);
my(@updates);
while(<UPDATES>)
{
    chomp;
    my(@d) = split(/\t/);
    print join (", ", @d), "\n";
    my(%u) = map(($uf[$_], $d[$_]), 0..$#d);
    print join (", ", %u), "\n";
    $updates{$u{id}} = \%u;
}
    
open(PLACES, "Gaz_places_53.txt");
chomp($f = scalar(<PLACES>));
while(<PLACES>){
    chomp;
    my(@d) = split(/\t/, $_);
    $name = $d[3];
    $name =~ s/\s\w+$//;
    $rname = reverse $name;
    $names{$rname}++;
    push @{$loc{lc $name}}, [@d[8..9]];
}
@names = keys %names;
$namergxp = "\\b" . join('|', reverse sort { length $a <=> length $b } @names) . "\\b";
my($seattlelat, $seattlelong) = @{$loc{seattle}[0]};

open(ZIP, "Gaz_zcta_national.txt");
chomp($f = scalar(<ZIP>));
while(<ZIP>)
{
    chomp;
    @d = split(/\t/, $_);
    my($zip, $aland, $awater, $aland_sqmi, $awater_sqmi, $long, $lat) = @d;
    if(($d = &Haversine($seattlelat, $seattlelong, $lat, $long)) < 75)
    {
	$ziploc{$zip} = [$long, $lat, $d];
    }
}
foreach my $zip (sort { $ziploc{$a}[2] <=> $ziploc{$b}[2] } keys %ziploc)
{
#    print $zip, "\t", $ziploc{$zip}[2], "\n";
}

$/ = "\r\n";
open(MEETINGS, "meetings.txt");
chomp($f = scalar(<MEETINGS>));
my(@f) = split(/\t/, $f);
grep($f{lc $f[$_]} = $_, 0..$#f);
unless($f{city})
{
    push @f, 'city';
$f{city} = $#f;
}
unless($f{state})
{
    push @f, 'state';
$f{state} = $#f;
}

foreach my $f (@uf)
{
    if(exists $f{lc $f})
{
}
else
{
    push @f, $f;
    $f{lc $f} = $#f;
}
}
#splice(@f, scalar(@f), , grep(!defined $f{lc $_}, @uf));
#print ("eep = ",(join("\n", @f), "\n"));

print OUTPUT join("\t", @f), "\n";

while(<MEETINGS>)
{
    chomp;
    @r = split(/\t/);
#    next unless $r[$f{id}] == 529;
#    printf "%40s %38s\n",  $r[$f{location}], $r[$f{address}];
#    my $loc = 
    my $u = $updates{$r[$f{id}]};
    if(ref $u)
{
    foreach my $fu (keys %{$u})
{
    $r[$f{$fu}] = $u->{$fu} if length($u->{$fu}) > 0;
}
#    grep($r[$f{$_}] = $u->{$_}, keys %{$u});
#    die;
}
#    grep($r[$f{$_}] = $updates{$r[$f{id}]}{$_}, keys %{$updates{$r[$f{id}]}}) if defined $updates{$r[$f{id}]};

    if($r[$f{location}] =~ /9[98]\d\d\d/)
{
    $zip = $&;
    if($zip != $r[$f{zip}] && $r[$f{zip}])
    {
	print "extracted zip code does not match\n";
	$zip = $r[$f{zip}];
    }
    $r[$f{zip}] = $zip;

    print $f{zip}, "\n";
    print "zip = ", $zip, "\t", $ziploc{$zip}[2], " ($r[$f{zip}])\n";
    my $d = $ziploc{$zip}[2];
    if($d>  40){
	print "alert!! $r[$f{location}]\n";
    }

    print "distance = ", $ziploc{$zip}[2], "\n";
}
    unless($r[$f{city}] || $r[$f{zip}])
    {
	my $city;
	if(lc $r[$f{area}] eq 'central')
{
    $city = 'Seattle';
}
else
{

	if((reverse $r[$f{location}]) =~ m!$namergxp!i)
{
    $city = reverse $&;
    my($lat2, $long2) = @{$loc{lc $city}[0]};
#    print "$lat $long $lat2 $long2\n";
    my $cd = &Haversine($seattlelat, $seattlelong, $lat2, $long2);
    if($cd > 50)
{
    print STDERR $city . ' ' . $cd, "\n";
}
    print "city distance = ", $cd, "\n";
$r[$f{city}] = $city if $city;
    
}
}
if($city eq 'Union')
{
    print $r[$f{location}], "\n";
}

printf "%-20s %s\n", $city, $r[$f{location}];
    }

$r[$f{state}] = 'WA';
unless($r[$f{city}] || $r[$f{zip}])
{
    print STDERR $r[$f{location}], "\n";
}
print OUTPUT join("\t", @r), "\n";

}

close(OUTPUT);
sub Haversine {
    my ($lat1, $long1, $lat2, $long2) = @_;
    my $r=3956;

               
    $dlong = deg2rad($long1) - deg2rad($long2);
    $dlat  = deg2rad($lat1) - deg2rad($lat2);

  $a = sin($dlat/2)**2 +cos(deg2rad($lat1)) 
                    * cos(deg2rad($lat2))
                    * sin($dlong/2)**2;
    $c = 2 * (asin(sqrt($a)));
    $dist = $r * $c;               


    return $dist;

}
