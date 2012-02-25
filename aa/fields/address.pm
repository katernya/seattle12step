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
  my $zips = $self->{_context}{zips};
  my $log_fh = $self->{_context}{LogFileHandle};
  my $forceGeocoding = $self->{_context}{ForceGeocoding};

  ## parse address
  if($Clubs{$address})
    {
    }
  else
    {
      my(%locationAttrs);
      
      my $location = $address;
      $locationAttrs{OrigLocationValue} = $location;

      $log_fh->print("\n********************************\nOriginal Location Value:\t$location\n\n");

      my $fixedUpLocation = $self->fixup($location);
      $locationAttrs{PostSubstValue} = $fixedUpLocation;

      $log_fh->print("Post Substitution Value\n\t$fixedUpLocation\n\n");

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

	  my $zip = $zips->getZipByCode($zipcode);
	  $locationAttrs{RelevantZipCode} = $zipcode;
	  $log_fh->print("Relevant Zip Code:\n\t$zipcode\n\n");
	}
      else
	{
	  splice(@l, scalar(@l), 0, $fixedUpLocation);
	}

      @l = grep(/[\S^,]/, @l);

      $log_fh->print("Current location array:\n\t", map("[$_] $l[$_]; ", 0..$#l), "\n\n");
		
      my(@l2);
      while (defined(my $part = pop @l)) {
	my $rpart = reverse $part;
		    
	if (($placeName) = $rpart =~ /($placeRgxp)/) {
	  $log_fh->print("Relevant Plce Name\n\t" . (reverse $placeName) . "\n\n");
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

      my(@l3);
      while (defined(my $part = shift @l2))
	{
	  next unless $part =~ /[\S^,]/;
	  if($part =~ /\([^\)]*\)/)
	    {
	      push @l3, $`;
	      push @l3, $&;
	      push @l3, $';
	    }
	  else
	    {
	      push @l3, $part;
	    }
	}
	
#      my(@l3) = grep(s/,\s*$// || 1, grep(/[\S^,]/, @l2));

      $log_fh->print("Location with zip/city removed: ", join(";", @l3), "\n");
		
      my $firstPart = shift @l3;
      my $locationName; 
      my $rest;
      if ($firstPart !~ /^\d\d/) {
	($locationName, $rest) = $firstPart =~ /([^,]+),\s*(.*)$/;
      } else {
	$rest = $firstPart;
      }

      $log_fh->print("Determined Location Name:\n\t$locationName\n\n");

      $locationAttrs{LocationName} = $locationName;
      $locationAttrs{Remainder} = $rest;

      $log_fh->print("Remainder of address field value:\n\t$rest\n\n");
		
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
      if ($forceGeocoding || !exists $geocache->{$address}) {
	my $inputAddress = $locationAttrs{Remainder} . ", " .
	  $locationAttrs{RelevantPlaceName} . ", WA " . $locationAttrs{RelevantZipCode};

	$log_fh->print("performing geocoding on:\n\t$inputAddress\n");

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
	  $log_fh->print("Ambiguous geocode result ($nresults)");
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
      $log_fh->print("checking place cache for $address\n");
      my $placecachejson = $placecache->{$address};
      $log_fh->print($placecachejson);

      my $placeresponse;
      my $cachedPlaceResponse;
      my $gotValidPlaceCacheHit;
      if (defined $placecachejson) {

	my $placecachehash = decode_json($placecachejson);
	$cachedPlaceResponse = $placecachehash->{Response};
	if ($cachedPlaceResponse->{status} eq 'ZERO_RESULTS')
	  {
	    if((time - $placecachehash->{RequestTime}) >= $::ResultExpirationSeconds)
	      {
		$log_fh->print("zero results in place cache, time to re-search.");
		$performPlaceLookup = 1;
	      }
	    else
	      {
		$log_fh->print("zero results in place cache, not time to re-search.");
	      }
	  } else {
	    if ($cachedPlaceResponse->{status} ne 'OK') {
	      $performPlaceLookup = 1;
	    } else {
	      my $nResults = @{$cachedPlaceResponse->{results}};
	      #			    if($placeresponse->{results}[0]{name} eq 'Wenatchee National Forest')
	      #			      {
	      #				$performPlaceLookup = 1;
	      #			      }
	      if($nResults == 1)
		{
		  $gotValidPlaceCacheHit = 1;
		}
	      else
		{
		  $performPlaceLookup = 1;
		}
	    }
	  }
      } else {
	$performPlaceLookup = 1;
      }

      if($gotValidPlaceCacheHit)
	{
	  $log_fh->print("Got valid place cache hit");
	}

      if (!$self->{_context}->{DisablePlaceSearch} && $performPlaceLookup) {
	die;
		    
	my $locName = $locationAttrs{LocationName};
	$locName =~ s/Ch\b/Church/;
		    
	die unless $locName;
	$log_fh->print("checking $locName\n");
		    
	my $url = new URI::URL "https://maps.googleapis.com/maps/api/place/search/json"; 
	my $inputLocation = $geolat .','. $geolong;
	$url->query_form(key => 'AIzaSyDOx6l9jZFmyR1pE2ZU62PXe-fSWHrnop4',				
			 'location' => $inputLocation, radius => $radius, sensor => 'false', name => $locName);
	my $req = new HTTP::Request('GET' => $url);
	$log_fh->print($req->as_string);
	my $response = $::UserAgent->request($req);
	#		    die;
	my $placejson = $response->content();
	$placeresponse = decode_json($placejson);
	$log_fh->print($placejson, "\n");
	$log_fh->print($placeresponse->{status}, "\n");
	my(%placeCacheHash) = ('Response' => $placeresponse, 'Input' => { 'location' => $inputLocation, radius => $radius, name => $locName }, RequestTime => time);
	$placecache->{$address} = encode_json(\%placeCacheHash);
      } else {
	$placeresponse = $cachedPlaceResponse;
      }

      my $placeresult = {};
      if ($placeresponse->{status} eq 'OK') {
	if (scalar(@{$placeresponse->{results}}) > 1) {
	  $log_fh->print("ambiguous place result\n");
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
  my $rgxp = join("|",keys %Cities);
  $l =~ s/($rgxp)/$Cities{$1}/ge;
  return $l;
}

1;
