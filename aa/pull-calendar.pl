#!/usr/local/ActivePerl-5.14/bin/perl

unshift @INC, "../perl-lib";

use JSON;
use strict;
require URI::URL;
use Date::Parse;
require Data::UUID;
use DBI;
use HTML::Entities;
require FileHandle;
require 'parse.pl';
require RecoveryAlphabet::Geo::Places;
require RecoveryAlphabet::Geo::Zips;
use DB_File;

my(%geocache);
my $geocache = tie(%geocache, 'DB_File', "geocache2.db", O_CREAT|O_RDWR, 0640, $DB_HASH);
die unless $geocache;

my(%placecache);
my $placecache = tie(%placecache, 'DB_File', "placecache.db", O_CREAT|O_RDWR, 0640, $DB_HASH);
die unless $placecache;


my $places = new RecoveryAlphabet::Geo::Places();
my $zips = new RecoveryAlphabet::Geo::Zips();

my(@places) = $places->within_radius_of(50, 'Seattle');
my(@placeNames) = map($_->{NAME}, @places);
grep((s/\s+\w+$//), @placeNames);
my $placeRgxp = join('|', grep((s/(?<!^)\b(?!(\s|$))/\\s*/g, s/\\s\*\\\s\\s\*/\\s+/g, 1), map(quotemeta(reverse $_), @placeNames)));

my(@zips) = $zips->within_radius_of(50, $places->getPlaceByName('Seattle'));
my(@codes) = map($_->{GEOID}, @zips);
my $zipRgxp = join('|', map(scalar(reverse), @codes));
 
my $webgiskey;
open(WEBGISKEY, "webgiskey.txt");
chomp($webgiskey = <WEBGISKEY>);

## need some better logic here
my(%clubs);
open(CLUBS, "clubs.txt");
while(<CLUBS>)
{
    chomp;
    $clubs{$_}++;
}

## isolate GIS functions
my(@gisf);
open(GISFIELDS, "fields.txt");
while(<GISFIELDS>)
{
    chomp;
    push @gisf, $_;
}



$::JSON = JSON->new->allow_nonref;
$::OutputDir = "/tmp";
$::TextOutputFilename = 'meetings.txt';
$::TextOutputFileFullPath = $::OutputDir . '/' . $::TextOutputFilename;

$::UUID = new Data::UUID();
$::RunUUID = $::UUID->to_string($::UUID->create());

$::TextOutputFileHandle = new FileHandle '>' . $::TextOutputFileFullPath;
unless($::TextOutputFileHandle)
{
    print STDERR "Unable to create text output file $::TextOutputFileFullPath: $!\n";
    return;
}

my $dbh = DBI->connect("dbi:Pg:dbname=staging", "kay", "lizard");

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
my(%flags);
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

    ## html cache
    ## need logic to handle update files on server
    ## right now the cache files must be deleted

    my $html;
    if(open(DAY, "../cache/$day.html"))
      {
	$html = join('', <DAY>);
      }
    else
      {
	my $req = new HTTP::Request(GET => $url);
	my $response = $ua->request($req);
	$html = $response->content();
	open(DAY, ">../cache/$day.html");
	print DAY $html;
	close(DAY);
      }

    ## done html cache

    my(@html) = split(/\r\n/, $html);
    my(@rows);
    my(@row);
    my $l;
    ## we need some error handling to detect if our screen-scraping algorithm is out of date
    while(my $line = shift @html)
    {
	$l++;
	if($line =~ /^last\s+updated\s+((\S+)\s+(\d{1,2})\s*,\s*(\d{4}))/i)
	  {
	    my $time = str2time($1);
	    ## need to do something useful with this value
	    print STDERR $time, "\n";
	  }
	
	if($line eq '<TR>')
	  {
	    @row = ();
	    # beggining of new row
	  }
	elsif($line =~ m!^<TD>(.*)</TD>!)
	  {
	    ## this logic works because the data columns are simply the TD element content, excluding BR elements
	    my $data = $1;

	    ## remove line break so it doesn't end up in our data
	    $data =~ s!<br>!!gi;

	    decode_entities($data);

	    push @row, $data;
	  }
	elsif($line eq '</TR>')
	  {
	    # end of row

	    ## skip header rows (table rows without any data cells, i.e. all TH elements)
	    next if scalar(@row) == 0;

	    ## populate our @rows array with a newly created array reference
	    ## the reference of @row itself is not taken as we re-use that array for each row
	    push @rows, [@row];

	    ## execute our prepared query with our data argumenta
	    $sth->execute($::RunUUID, $ENV{HOSTNAME}, $url, $mi, @row);

	    ## what follows is our custom parsing code

	    ## @meeting and %meeting are variables for use in outputting JSON for testing and development purposes
	    my(@meeting);
	    my(%meeting);

	    ## Populate some %meeting key/value pairs
	    $meeting{OriginalRow} = [@row];

	    $meeting{Division} = $row[0];
	    $meeting{Time} = $row[1];
	    $meeting{OpenClosed} = $row[2];
	    $meeting{Name} = $row[3];
	    $meeting{NoteDisp} = $row[4];

	    my $time = $row[1];
	    if($time =~ /^\s*midnight\s*$/i)
	      {
		$time = "11:59 PM";
	      }
	    if($time =~ /^\s*noon\s*$/i)
	      {
		$time = "12:00 PM";
	      }
	    my($hour, $min, $ampm);
	    ($hour, $min, $ampm) = $time =~ m!^\s*(\d{1,2}):(\d{2})\s+(AM|PM)\s*$!;
	    if($ampm eq 'PM' && $hour != 12)
	      {
		$hour += 12;
	      }
	    $time = sprintf("%02d%02d", $hour, $min);
	    $row[1] = $time;

	    $meeting{ParsedTime} = $time;

	    my(@flags) = split(' ', $row[5]);
	    my $flagval = 0;
	    foreach my $flag (@flags)
	      {
		$flagval += $flags{$flag};
	      }
	    $row[5] = $flagval;

	    my($address);
	    if($clubs{$row[4]})
	      {
	      }
	    else
	      {
		my(%locationAttrs);

		my $location = $row[4];
		$locationAttrs{OrigLocationValue} = $location;
		my $fixedUpLocation = &fixup($location);
		$locationAttrs{PostSubstValue} = $fixedUpLocation;
		my($placeName);
		my $rloc = reverse $fixedUpLocation;
		
		my(@locationParts);
		
		my(@l);
		my $zipcode;
		if(($zipcode) = $rloc =~ /($zipRgxp)/)
		  {
		    $zipcode = reverse $zipcode;
		    my $preZip = reverse $';
		    my $postZip = reverse $`;
		    
		    splice(@l, scalar(@l), 0, $preZip, $postZip);
		    
		    $locationAttrs{RelevantZipCode} = $zipcode;
		    print STDERR "found relevant zip code: $zipcode\n";
		  }
		else
		  {
		    splice(@l, scalar(@l), 0, $fixedUpLocation);
		  }
		
		
		my(@l2);
		while(defined(my $part = pop @l))
		  {
		    my $rpart = reverse $part;
		    
		    print STDERR "checking $rpart\n";
		    if(($placeName) = $rpart =~ /($placeRgxp)/)
		      {
			print STDERR "found relevant location " . (reverse $placeName) . "\n";
			my $preLoc = reverse $';
			my $postLoc = reverse $`;
			$preLoc =~ s/\s*,\s*$//;
			
			$placeName = reverse $placeName;
			
			splice(@l2, 0, 0, $preLoc, 
			       # may potentially put object here
			       $postLoc);
			
			$locationAttrs{RelevantPlaceName} = $placeName;
			last;
			#      $locationAttrs{LocationParts} = \@locationParts;
		      }
		    else
		      {
			unshift @l2, $part;
		      }
		  }
		splice(@l2, 0, 0, @l);
		
		my(@l3) = grep(/[\S^,]/, @l2);
		
		my $firstPart = shift @l3;
		my $locationName; 
		my $rest;
		if($firstPart !~ /^\d\d/)
		  {
		    ($locationName, $rest) = $firstPart =~ /([^,]+),\s*(.*)$/;
		  }
		else
		  {
		    $rest = $firstPart;
		  }
		$locationAttrs{LocationName} = $locationName;
		$locationAttrs{Remainder} = $rest;
		
		$locationAttrs{LocationParts} = \@l3;
		# this just removes a discovered location from the string
		# probably better to split the string
		#      $rloc =~ s/($placeRgxp)//;
		#      $fixedUpLocation = reverse $rloc;
		#    }
		
		push @::Locations, \%locationAttrs;
		#  print $::JSON->pretty->encode(\%locationAttrs), "\n";
		#  $::Count++;
		#  exit if $::Count == 2;
		
		if($::ForceGeocoding || !$geocache{$row[4]})
		  {
		    my $address = $locationAttrs{Remainder} . ", " . $locationAttrs{RelevantPlaceName} . ", WA " . $locationAttrs{RelevantZipCode};
		    print "geocoding $address\n";
		    my $url = new URI::URL "http://maps.googleapis.com/maps/api/geocode/json";
		    $url->query_form('address' => $address, 'sensor' => 'false', 'region' => 'us');
		    my $req = new HTTP::Request('GET' => $url);
		    my $response = $ua->request($req);
		    $geocache{$row[4]} = $response->content();
		  }
		my $geocodeResponse = decode_json($geocache{$row[4]});

		my($geocoderesult) = {};
		if($geocodeResponse->{status} eq 'OK')
		  {
		    my $nresults = scalar(@{$geocodeResponse->{results}}) ;
		    if($nresults > 1)
		      {
			print STDERR "Ambiguous geocode result ($nresults)";
#			next;
		      }

		    $geocoderesult = $geocodeResponse->{results}[0];
		  }
		
		my $geoloc = $geocoderesult->{geometry}{location};
		my($geolat, $geolong, $radius);
		if(ref $geoloc)
		  {
		    $geolat = $geoloc->{lat};
		    $geolong = $geoloc->{lng};
		    $radius = 500;
		  }
		else
		  {
		    $geolat = $places->getPlaceByName('Seattle')->latitude;
		    $geolong = $places->getPlaceByName('Seattle')->longitude;
		    $radius = 80000;
		  }
		
		#  print $geocache{$row[4]}, "\n";
		
		print STDERR "checking place cache for $row[4]\n";
		my $placejson = $placecache{$row[4]};
		if(!$placejson)
		  {
		    print $::JSON->pretty->encode(\%locationAttrs);
		    
		    my $locName = $locationAttrs{LocationName};
		    $locName =~ s/Ch\b/Church/;
		    
		    print "checking $locName\n";
		    
		    my $url = new URI::URL "https://maps.googleapis.com/maps/api/place/search/json";
		    $url->query_form(key => 'AIzaSyDOx6l9jZFmyR1pE2ZU62PXe-fSWHrnop4',
				     'location' => $geolat .','. $geolong, radius => $radius, sensor => 'false', name => $locName);
		    my $req = new HTTP::Request('GET' => $url);
		    print $req->as_string;
		    my $response = $ua->request($req);
#		    die;
		    $placejson = $placecache{$row[4]} = $response->content();
		  }
		
		my $placeresponse = decode_json($placejson);
		my $placeresult = {};
		if($placeresponse->{status} eq 'OK') 
		  {
		    if(scalar(@{$placeresponse->{results}}) > 1)
		      {
			print STDERR "ambiguous place result\n";
			#die;
		      }
		    $placeresult = $placeresponse->{results}[0];
		  }

		my(%resultAttrs);
		$resultAttrs{PlaceName} = $placeresult->{name};
		$resultAttrs{PlaceLatitude} = $placeresult->{geometry}{location}{lat};
		$resultAttrs{PlaceLongitude} = $placeresult->{geometry}{location}{lng};
		$resultAttrs{FormattedAddress} = $geocoderesult->{formatted_address};

		push @meeting, encode_json(\%meeting);
		push @meeting, \%resultAttrs;
		push @meeting, \%locationAttrs;
		push @::Meetings, [ \%meeting, \%resultAttrs ];
#		push @meeting, $geocoderesult;
#		push @meeting, $placeresult;
		
		
#		my(%c);#a
#		foreach $component (@{$geocoderesult{address_components}})
#		  {
		    


#		print '[', join("\n", map(ref $_ ? $::JSON->pretty->encode($_) : $_, @meeting)), "\n", '],', "\n";
		
		
		    
		if(0)
		  {
		    # this is for the webgis service
		    my $content = $geocache{$row[4]};
		    
		    #  unmy($address) = &parseaddress($loc);
		    #	    my($unparsed) = join(" ", @{$address});
		    my $unparsed = $address;
		    my(@gisd);
		    my(%gisd);
		    if($content)
		      {
			@gisd = split(/\t/, $content);
			(@gisd) = split(/\t/, $content);
			(%gisd);
			@gisd{@gisf} = @gisd;
		      }
		    unless($gisd{'Matching Geography Type'} eq 'StreetSegment')
		      {
			print "unparsed = $unparsed\n";
			my $gisurl = new URI::URL 'https://webgis.usc.edu/Services/Geocode/WebService/GeocoderWebServiceHttpNonParsed_V02_96.aspx';
			$gisurl->query_form('apiKey' => $webgiskey, version => 2.96, streetAddress => $unparsed, city => ($placeName || 'Seattle'), state => 'WA', format => 'tsv', );
			my $req = new HTTP::Request 'GET' => $gisurl;
			my $content = $ua->request($req)->content();
			
			(@gisd) = split(/\t/, $content);
			(%gisd);
			@gisd{@gisf} = @gisd;
			print map($_ . " = " . $gisd{$_} . "\n", @gisf);
			die $row[4] || $unparsed unless $gisd{'Matching Geography Type'} eq 'StreetSegment';
			$geocache{$row[4]} = $content;
		      }
		    else
		      {
		      }
		    
		    print "\t", $gisd{Latitude}, "\t", $gisd{Longitude}, "\n";
		  }
	      }
	    
	    $::TextOutputFileHandle->print($mi,"\t", $day, "\t", join("\t", @row), "\n");
	    $mi++;
	  }
      }
  }

print $::JSON->pretty->encode(\@::Meetings);
#print $::JSON->pretty->encode(\@::Locations);

#print join(", ", keys %area), "\n";
#print join(", ", keys %flags), "\n";

