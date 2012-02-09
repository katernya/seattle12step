#!/usr/bin/perl

unshift @INC, "../perl-lib";

require URI::URL;
use Date::Parse;
require OSSP::uuid;
use DBI;
use HTML::Entities;
require FileHandle;
require 'parse.pl';


open(CLUBS, "/home/kay2/clubs.txt");
while(<CLUBS>)
{
    print;
    chomp;
    $clubs{$_}++;
}

open(GISFIELDS, "fields.txt");
while(<GISFIELDS>)
{
    chomp;
    push @gisf, $_;
}



$::OutputDir = "/tmp";
$::TextOutputFilename = 'meetings.txt';
$::TextOutputFileFullPath = $::OutputDir . '/' . $::TextOutputFilename;

$::UUID = new OSSP::uuid();
$::UUID->make("v1");
$::RunUUID = $::UUID->export("str");

$::TextOutputFileHandle = new FileHandle '>' . $::TextOutputFileFullPath;
unless($::TextOutputFileHandle)
{
    print STDERR "Unable to create text output file $::TextOutputFileFullPath: $!\n";
    return;
}

my $dbh = DBI->connect("dbi:Pg:dbname=staging");


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

$::TextOutputFileHandle->print(join("\t", qw(id day area time open name location flags address)), "\n");

my($mi) = 1;
my(@days) = qw(sunday monday tuesday wednesday thursday friday saturday);
my $webprefix = "http://seattleaa.org/directory/web";
my $ua = new LWP::UserAgent();

my $sth = $dbh->prepare('INSERT INTO seattleaadirectory (importrunuuid, importhost, sourceurl, rownum, divisions, time, openclosed, name, address, notedisp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

foreach my $day (@days)
{
    my $url = $webprefix . $day . '.html';

    my $req = new HTTP::Request(GET => $url);
    my $response = $ua->request($req);
    my $html = $response->content();
    my(@html) = split(/\r\n/, $html);
    my(@rows);
    my(@row);
    my $l;
    while(my $line = shift @html)
    {
	$l++;
	if($line =~ /^last\s+updated\s+((\S+)\s+(\d{1,2})\s*,\s*(\d{4}))/i)
{
    my $time = str2time($1);
    print STDERR $time, "\n";
}

	if($line eq '<TR>')
	{
	    @row = ();
	    # beggining of new row
	} elsif($line =~ m!^<TD>(.*)</TD>!)
	{
	    my $data = $1;
	    $data =~ s!<br>!!gi;
	    decode_entities($data);
	    push @row, $data;
	} elsif($line eq '</TR>')
	{
	    # end of row
	    next if scalar(@row) == 0;

	    $sth->execute($::RunUUID, $ENV{HOSTNAME}, $url, $mi, @row);

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
		  $address = join(" ", grep(defined $_, @{$r})) unless $address
		      ;


;
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
	    if($clubs{$row[4]})
{
}
else
{
	    my($address) = &parseaddress($row[4]);
	    my($unparsed) = join(" ", @{$address});
		my $gisurl = new URI::URL 'https://webgis.usc.edu/Services/Geocode/WebService/GeocoderWebServiceHttpNonParsed_V02_96.aspx';
	    $gisurl->query_form('apiKey' => $webgiskey, version => 2.96, streetAddress => join(" ", grep($_, @{$address})), city => 'Seattle', state => 'WA', format => 'tsv');
		  my $req = new HTTP::Request 'GET' => $gisurl;
	    my $content = $ua->request($req)->content();
	    my(@gisd) = split(/\t/, $content);
	    my(%gisd);
	    @gisd{@gisf} = @gisd;
	    die $row[4] || $unparsed unless $gisd{'Matching Geography Type'} eq 'StreetSegment';
	    print "\t", $gisd{Latitude}, "\t", $gisd{Longitude}, "\n";
}


	    $::TextOutputFileHandle->print($mi,"\t", $day, "\t", join("\t", @row, join(" ", grep($_, @{$address}))), "\n");
	    $mi++;
	}
    }
}
#print join(", ", keys %area), "\n";
#print join(", ", keys %flags), "\n";

