#!/usr/bin/perl


require 'parse.pl';

#my($long, $lat) = (47.620499, -122.350876)
#open(Z, "Gaz_zcta_national.txt");
#while(<Z>)
#  {
#    chomp($_);
#    ($zip, $aland, $awater, $aland_sqmi, $awater, $sqmi, $intptlong, $intptlat)# = split(/\t/, $_);
#    
#  }


require LWP::UserAgent;
require HTTP::Request;

my(@flags) = qw(an at cc gs mo oh si sp ss wb we wo wp yp);
for(my $i = 0; $i < $#flags; $i++)
{
    $flags{$flags[$i]} = 2 ** $i;
}

print join("\t", qw(id day area time open name location flags address)), "\n";

my($mi) = 1;
my(@days) = qw(sunday monday tuesday wednesday thursday friday saturday);
my $webprefix = "http://seattleaa.org/directory/web";
my $ua = new LWP::UserAgent();
$sth = $dbh->prepare('INSERT INTO seattleaadirectory (im

foreach my $day (@days)
{
    my $req = new HTTP::Request(GET => $webprefix . $day . '.html');
    my $response = $ua->request($req);
    my $html = $response->content();
    my(@html) = split(/\r\n/, $html);
    my(@rows);
    my(@row);
    my $l;
    while(my $line = shift @html)
    {
	$l++;
	if($line eq '<TR>')
	{
	    @row = ();
	    # beggining of new row
	} elsif($line =~ m!^<TD>(.*)</TD>!)
	{
	    my $data = $1;
	    $data =~ s!<br>!!gi;
	    push @row, $data;
	} elsif($line eq '</TR>')
	{
	    # end of row
	    next if scalar(@row) == 0;
	    push @rows, [@row];
	    $area{$row[0]}++;
	    my $time = $row[1];
	    if($time =~ /^\s*midnight\s*$/i)
	    {
		$time = "11:59 PM";
	    }
	    my($hour, $min, $ampm);
	    ($hour, $min, $ampm) = $time =~ m!^\s*(\d{1,2}):(\d{2})\s+(AM|PM)\s*$!;
	    if($ampm eq 'PM')
	    {
		$hour += 12;
	    }
	    $time = sprintf("%02d%02d", $hour, $min);
	    $row[1] = $time;
	    my(@flags) = split(' ', $row[5]);
	    my $flagval = 0;
	    foreach my $flag (@flags)
	    {
		$flagval += $flags{$flag};
	    }
	    $row[5] = $flagval;
	
if(0) {
    my(@add) = split(/,\s*/, $row[4]);
	    my $i = 0;
	    my $address = undef;
	    while(my $add = shift @add)
	    {
		$add =~ s/&amp;/&/g;
		my $r = &parseaddress($add);
		unless(defined $r)
		{
#		    print "$i: $add\n";
		}
		else
		{
		  $address = join(" ", grep(defined $_, @{$r})) unless $address;
#		    print "$i: $add\n";
#		    print "address: ", join("|", grep(defined $_, @{$r})), "\n";
		}
		$i++;
	    }
#	    unless($address)
#	      {
	    print $row[4],"\n" unless $row[0] eq 'CENTRAL';
#	  }
#	    print $address, "\n";
}
	    my($address) = &parseaddress($row[4]);
	    print $mi,"\t", $day, "\t", join("\t", @row, join(" ", grep($_, @{$address}))), "\n";
	    $mi++;
	}
    }
}
#print join(", ", keys %area), "\n";
#print join(", ", keys %flags), "\n";

