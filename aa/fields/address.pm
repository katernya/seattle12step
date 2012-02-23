package aa::fields::address;

use JSON;

require URI::URL;
require LWP::UserAgent;

use strict;
use vars qw (%Clubs %Cities);

%Clubs = map { $_ => 1 } ('', 'South King Alano Club', 'Alano Club of the Eastside', 'Lynnwood Alano Club', 'Fremont Fellowship Hall', 'Phoenix Club', '12 & 12 Fellowship', '1504 Club', 'A New Beginning', 'Cherry Fellowship', 'Eastside Alano Club', 'South County Alano Club', 'Closed step on request', 'Step study on request', '12&12 FELLOWSHIP', 'Fremont Fellowship', 'Our Lady of Mt. Virgin Parish Hall', '12 & 12 Fellowship (Big BookStudy)', '12 & 12 Fellowship Hall', '12 & 12 Fellowship Hall -  Step Study', '12 & 12 Study', '1504  Club', '2609 Larch Way, Lynnwood', '3rd Sat is Birthday Meeting', 'A New Beginnning', 'Alano Club of the Eastside, Annex', 'Alano Club of the Eastside, Big Book Study', 'Alano Club of the Eastside, Candlelight', 'Alano Club of the Eastside(candlelight)', 'B\'days 2nd & last Sat', 'Birthday Meeting', 'Book Study in side room', 'Business Meeting 1st Sat', 'Calvary Presbyterian Ch-enter on Wells', 'CHAC Satellite, Seattle University \'s Bannon Engineering Bldg, Rm. 311', 'CHAC Satellite, Seattle University\'s Administration Bldg, Rm 321', 'East Does It Hall', 'Fire Hall, 8641 Preston-Fall City Rd SE, Preston 98050', 'For directions call 425 432 8887', 'Fremont  Fellowship Hall', 'Fremont Fellowship  Hall', 'Last Sat of month only', 'On Alki Beach across from Alki Bakery', 'please call 206 291 5495 for location', 'Sacred Heart Catholic Ch, Enumclaw', 'Serenity Hall', 'South King  Alano Club');

%Cities = (#'Seattle' => 1,
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

sub resultAttributes { shift->{_resultAttributes} }
sub locationAttributes { shift->{_locationAttributes} }

sub new {
  my $class = shift;
  my $context = shift;
  my $fvalue = shift;
  my $self = { _context => $context, _inputValue => $fvalue };
  if(!ref $::UserAgent)
    {
      $::UserAgent = new LWP::UserAgent;
    }
  bless $self, $class;
}

sub process_input {
  my $self = shift;

  my $address = $self->{_inputValue};

  my $zipRgxp = $self->{_context}{zipRgxp};
  my $placeRgxp = $self->{_context}{placeRgxp};
  my $geocache = $self->{_context}{geocache};
  my $placecache = $self->{_context}{placecache};
  my $places = $self->{_context}{places};

  ## parse address
  if($Clubs{$address})
    {
    }
  else
    {
      my(%locationAttrs);
      
      my $location = $address;
      $locationAttrs{OrigLocationValue} = $location;
      my $fixedUpLocation = $self->fixup($location);
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
      while (defined(my $part = pop @l)) {
	my $rpart = reverse $part;
		    
	print STDERR "checking $rpart\n";
	if (($placeName) = $rpart =~ /($placeRgxp)/) {
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
	} else {
	  unshift @l2, $part;
	}
      }
      splice(@l2, 0, 0, @l);
		
      my(@l3) = grep(/[\S^,]/, @l2);
		
      my $firstPart = shift @l3;
      my $locationName; 
      my $rest;
      if ($firstPart !~ /^\d\d/) {
	($locationName, $rest) = $firstPart =~ /([^,]+),\s*(.*)$/;
      } else {
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
		
      #  print $::JSON->pretty->encode(\%locationAttrs), "\n";
      #  $::Count++;
      #  exit if $::Count == 2;

      my $geocodeContent;
      my $geocodeResponse;
      if ($::ForceGeocoding || !exists $geocache->{$address}) {
	my $inputAddress = $locationAttrs{Remainder} . ", " .
	  $locationAttrs{RelevantPlaceName} . ", WA " . $locationAttrs{RelevantZipCode};
	print STDERR "geocoding $inputAddress\n";
	my $geocodeurl = new URI::URL "http://maps.googleapis.com/maps/api/geocode/json";
	$geocodeurl->query_form('address' => $inputAddress, 'sensor' => 'false', 'region' => 'us');
	my $req = new HTTP::Request('GET' => $geocodeurl);
	my $response = $::UserAgent->request($req);
	$geocodeContent = $response->content();
	
	$geocodeResponse = decode_json($geocodeContent);

	$geocache->{$address} = $geocodeContent;
      }
      else
	{
	  $geocodeContent = $geocache->{$address};
	  $geocodeResponse = decode_json($geocodeContent);
	}
	  
      my($geocoderesult) = {};
      if ($geocodeResponse->{status} eq 'OK') {
	my $nresults = scalar(@{$geocodeResponse->{results}}) ;
	if ($nresults > 1) {
	  print STDERR "Ambiguous geocode result ($nresults)";
	  #			next;
	}

	$geocoderesult = $geocodeResponse->{results}[0];
      }
		
      my $geoloc = $geocoderesult->{geometry}{location};
      my($geolat, $geolong, $radius);
      if (ref $geoloc) {
	$geolat = $geoloc->{lat};
	$geolong = $geoloc->{lng};
	$radius = 500;
      } else {
	$geolat = $places->getPlaceByName('Seattle')->latitude;
	$geolong = $places->getPlaceByName('Seattle')->longitude;
	$radius = 80000;
      }
		
		
      my $performPlaceLookup = 0;
      print STDERR "checking place cache for $address\n";
      my $placecachejson = $placecache->{$address};


      my $placeresponse;
      my $cachedPlaceResponse;
      if (defined $placecachejson) {
	my $placecachehash = decode_json($placecachejson);
	$cachedPlaceResponse = $placecachehash->{Response};
	if ($cachedPlaceResponse->{status} eq 'ZERO_RESULTS' && (time - $placecachehash->{RequestTime}) >= $::ResultExpirationSeconds) {
	  $performPlaceLookup = 1;
	} else {
	  if ($cachedPlaceResponse->{status} ne 'OK') {
	    $performPlaceLookup = 1;
	  } else {
	    #			    if($placeresponse->{results}[0]{name} eq 'Wenatchee National Forest')
	    #			      {
	    #				$performPlaceLookup = 1;
	    #			      }
	  }
	}
      } else {
	$performPlaceLookup = 1;
      }

      if (!$self->{_context}->{DisablePlaceSearch} && $performPlaceLookup) {
	die;
	print STDERR $::JSON->pretty->encode(\%locationAttrs);
		    
	my $locName = $locationAttrs{LocationName};
	$locName =~ s/Ch\b/Church/;
		    
	die unless $locName;
	print STDERR "checking $locName\n";
		    
	my $url = new URI::URL "https://maps.googleapis.com/maps/api/place/search/json"; 
	my $inputLocation = $geolat .','. $geolong;
	$url->query_form(key => 'AIzaSyDOx6l9jZFmyR1pE2ZU62PXe-fSWHrnop4',				
			 'location' => $inputLocation, radius => $radius, sensor => 'false', name => $locName);
	my $req = new HTTP::Request('GET' => $url);
	print STDERR $req->as_string;
	my $response = $::UserAgent->request($req);
	#		    die;
	my $placejson = $response->content();
	$placeresponse = decode_json($placejson);
	print STDERR $placejson, "\n";
	print STDERR $placeresponse->{status}, "\n";
	my(%placeCacheHash) = ('Response' => $placeresponse, 'Input' => { 'location' => $inputLocation, radius => $radius, name => $locName }, RequestTime => time);
	$placecache->{$address} = encode_json(\%placeCacheHash);
      } else {
	$placeresponse = $cachedPlaceResponse;
      }

      my $placeresult = {};
      if ($placeresponse->{status} eq 'OK') {
	if (scalar(@{$placeresponse->{results}}) > 1) {
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

      $self->{_resultAttributes} = \%resultAttrs;
      $self->{_locationAttributes} = \%locationAttrs;
    }
}

sub fixup {
  my $self = shift;
  my $l = shift;
  my $rgxp = join("|",keys %::cities);
  $l =~ s/($rgxp)/$::cities{$1}/ge;
  return $l;
}

1;
