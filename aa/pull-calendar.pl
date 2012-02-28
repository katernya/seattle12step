#!/usr/local/ActivePerl-5.14/bin/perl

unshift @INC, "../perl-lib";
use JSON;
use strict;
require URI::URL;
use Date::Parse;
use Text::Capitalize;
require Data::UUID;
use DBI;
use HTML::Entities;
require FileHandle;
require 'parse.pl';
require RecoveryAlphabet::Geo::Places;
require RecoveryAlphabet::Geo::Zips;
require 'fields/address.pm';

use DB_File;

my $log_fh = IO::Handle->new();
$log_fh->fdopen(fileno(STDERR), "w");

$::DisablePlaceSearch = 1;
$::ResultExpirationSeconds = 7 * 86400;
$::ForceGeocoding = 0;

@::ValidDivisions = ('NORTH', 'CENTRAL', 'EASTSIDE', 'WEST', 'SOUTH', 'SOUTH COUNTY');
grep($::ValidDivisions{$_}++, @::ValidDivisions);

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

my $Context = { geocache => \%geocache, placecache => \%placecache, DisablePlaceSearch => $::DisablePlaceSearch,
		LogFileHandle => $log_fh, zips => $zips , placeRgxp => $placeRgxp, zipRgxp => $zipRgxp, places => $places,
		ForceGeocoding => $::ForceGeocoding };
 
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



$::JSON = JSON->new();
$::JSON = $::JSON->allow_nonref;

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

my $querysth = $dbh->prepare("select meetingserialid from meetingsource where dayofweek = ? and divisions = ? and time = ? and openclosed = ? and name = ? and address = ? and notedisp = ?");

my $sth = $dbh->prepare('INSERT INTO meetingsource (importrunuuid, importhost, sourceurl, updateddate, dayofweek, rownum, divisions, time, openclosed, name, address, notedisp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

my(%input);
foreach my $day (@days)
  {
    my $url = $webprefix . $day . '.html';
    
    my $updateddate;

    ## html cache
    ## need logic to handle update files on server
    ## right now the cache files must be deleted

    my $html;
#    my $headreq = new HTTP::Request(HEAD => $url);
#    my $headresp = $ua->request($headreq);
#    print $headresp->as_string();

    if (open(DAY, "../cache/$day.html")) {
      $html = join('', <DAY>);
    } else {
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
    while (my $line = shift @html) {
      $l++;
      if ($line =~ /^last\s+updated\s+((\S+)\s+(\d{1,2})\s*,\s*(\d{4}))/i) {
	my $time = str2time($1);
	## need to do something useful with this value
	$updateddate = scalar(localtime($time));
	print STDERR $time, "\n";
      }
	
      if ($line eq '<TR>') {
	@row = ();
	# beggining of new row
      } elsif ($line =~ m!^<TD>(.*)</TD>!) {
	## this logic works because the data columns are simply the TD element content, excluding BR elements
	my $data = $1;

	## remove line break so it doesn't end up in our data
	$data =~ s!<br>!!gi;

	decode_entities($data);

	push @row, $data;
      } elsif ($line eq '</TR>') {
	# end of row

	## skip header rows (table rows without any data cells, i.e. all TH elements)
	next if scalar(@row) == 0;

	## populate our @rows array with a newly created array reference
	## the reference of @row itself is not taken as we re-use that array for each row

	$row[3] = capitalize_title($row[3]);

	push @rows, [@row];

	$querysth->execute($day, $row[0], $row[1], $row[2], $row[3], $row[4], $row[5]);
	my($id) = $querysth->fetchrow_array();
#	print $id, "\n";

	## execute our prepared query with our data argumenta
	$sth->execute($::RunUUID, $ENV{HOSTNAME}, $url, $updateddate, $day, $mi, @row) unless $id;

	## what follows is our custom parsing code

	## @meeting and %meeting are variables for use in outputting JSON for testing and development purposes
	my(@meeting);
	my(%meeting);



	## Populate some %meeting key/value pairs
	#	    $meeting{OriginalRow} = [@row];

	## we are hardcoding the field names here
	$meeting{Division} = $row[0];
	$meeting{Time} = $row[1];
	$meeting{OpenClosed} = $row[2];
	$meeting{Name} = $row[3];
	$meeting{Address} = $row[4];
	$meeting{NoteDisp} = $row[5];
	$meeting{DayOfWeek} = $day;

	unless ($::ValidDivisions{$row[0]}) {
	  die "Unknown division $row[0] (known divisions " . join(" ", keys %::ValidDivisions) . ")";
	}

	$::Division{$row[0]}++;

	## parse time
	my $time = $row[1];
	if ($time =~ /^\s*midnight\s*$/i) {
	  $time = "11:59 PM";
	}
	if ($time =~ /^\s*noon\s*$/i) {
	  $time = "12:00 PM";
	}
	my($hour, $min, $ampm);
	($hour, $min, $ampm) = $time =~ m!^\s*(\d{1,2}):(\d{2})\s+(AM|PM)\s*$!;
	if ($ampm eq 'PM' && $hour != 12) {
	  $hour += 12;
	}
	$time = sprintf("%02d:%02d:00", $hour, $min);
	    
	## set value in @row (necessary?)
	$row[1] = $time;

	$meeting{ParsedTime} = $time;

	## parse flags
	my(@flags) = split(' ', $row[5]);
	my $flagval = 0;
	foreach my $flag (@flags) {
	  $flagval += $flags{$flag};
	}
	$row[5] = $flagval;
	    
	## Parse address field
	my $addressField = new aa::fields::address ($Context, $row[4]);
	$addressField->process_input();

	my $resultAttrs = $addressField->resultAttributes();
	my $locationAttrs = $addressField->locationAttributes();

	## lame
	push @meeting, \%meeting;
	push @meeting, $resultAttrs;
	push @meeting, $locationAttrs;
	    
	push @::Meetings, \@meeting;
	    
	## these pushes are more useful for debugging			
	#		push @meeting, $geocoderesult;
	#		push @meeting, $placeresult;
	    
	    
	## unfinished code 		
	#		my(%c);#a
	#		foreach $component (@{$geocoderesult{address_components}})
	#		  {
	    
	    
	    
	# lame conditional prettyprinting
	#		print '[', join("\n", map(ref $_ ? $::JSON->pretty->encode($_) : $_, @meeting)), "\n", '],', "\n";
	    
	    
	## here is our TSV output code
	    
	$::TextOutputFileHandle->print($mi,"\t", $day, "\t", join("\t", @row), "\n");
	    
	## Increment meeting index
	$mi++;
      }
    }
  }

print STDERR "here\n";
print encode_json(\@::Meetings);

exit;
my(@fields);
my(%fieldidx);
foreach my $meeting (@::Meetings) {
  for (my $i = 0; $i < scalar(@{$meeting}); $i++) {
    foreach my $field (keys %{$meeting->[$i]}) {
      my $fname = "${i}_$field";
      unless (exists $fieldidx{$fname}) {
	push @fields, $fname;
	$fieldidx{$fname} = $#fields;
      }
    }
  }
}
print join ("\t", @fields),"\n";
foreach my $meeting (@::Meetings) {
  my(@d);
  foreach my $field (@fields) {
    my($idx, $key) = split(/_/, $field);
    my $v = $meeting->[$idx]{$key};
    push @d, ref $v eq 'ARRAY' ? join('|', @{$v}) : $v;
  }
  print join("\t", @d), "\n";
}

    
##print "Divisions: ", join(" ", keys %::Division), "\n";
##print $::JSON->pretty->encode(\@::Meetings);
#print $::JSON->pretty->encode(\@::Locations);

#print join(", ", keys %area), "\n";
#print join(", ", keys %flags), "\n";

#xprint $::JSON->pretty->encode(\%input);
