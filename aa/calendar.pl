use LWP::UserAgent;
require URI::URL;
require Time::Local;
use Date::Calc qw(:all);
use Date::ISO8601 qw(month_days cjdn_to_ymd ymd_to_cjdn present_ymd);

use JSON;

print time - 1330409794, "\n";

my $lastJson = '';

my $clientId = '';
## this is from the oauth callback
my $code = '';
##

my $secret = '';
my $calendarId = '';

my $ua = new LWP::UserAgent;

my($year, $month, $day) = Monday_of_Week(1, 2012);
my(%daysofweek) = ('monday' => 0,
		   'tuesday' => 1,
		   'wednesday' => 2,
		   'thursday' => 3,
		   'friday' => 4,
		   'saturday' => 5,
		   'sunday' => 6);

#https://www.googleapis.com/calendar/v3/calendars/calendarId/eventsprint $dow, "\n";


my($request, $response, $url);
unless($lastJson)
  {
    $url = new URI::URL 'https://accounts.google.com/o/oauth2/token';
    $url->query_form('code' => $code, client_id => $clientId,
		     client_secret => $secret, 'redirect_uri' => 'http://localhost/oauth2callback',
		     'grant_type' => 'authorization_code');
    my $x = $url->query();
    
    $url = new URI::URL 'https://accounts.google.com/o/oauth2/token';
    
    $request = new HTTP::Request 'POST' => $url;
    #$request->header('Content-length', length($x));
    
    $request->content_type('application/x-www-form-urlencoded');
    $request->content($x);
    $response = $ua->request($request);
    $lastJson = $response->content;
    my $d = decode_json($lastJson);
    my($cache) = { requestTime => time, response => $d };
    print encode_json($cache);
  }
    
my $d = decode_json($lastJson);


my $url = new URI::URL 'https://www.googleapis.com/calendar/v3/calendars/' . $calendarId . '/events';
$url->query_form('access_token' => $d->{access_token});
$request = new HTTP::Request 'GET' => $url;

my $url = new URI::URL 'https://www.googleapis.com/calendar/v3/calendars/' . $calendarId . '/clear';

$request = new HTTP::Request 'POST' => $url;
$request->header('Authorization', 'Bearer ' . $d->{access_token});
my $x = 'access_token=' . $d->{access_token};
$request->content($x);
$response = $ua->request($request);
print $response->as_string;
exit;

#$request->header('Host', 'www.googleapis.com');


open(MEETINGS, "meetings.json");
my $json = join('', <MEETINGS>);
my $meetings = decode_json($json);

foreach my $meeting (@{$meetings})
  {
    my($m, $r, $l) = @{$meeting};
    $url = new URI::URL 'https://www.googleapis.com/calendar/v3/calendars/' . $calendarId . '/events';
    my $cjdn = ymd_to_cjdn($year, $month, $day + $daysofweek{lc $m->{DayOfWeek}});
    my $startdate = present_ymd($cjdn);
    my $starttime = $m->{ParsedTime} . '-08:00';
    my $enddate;
    if($m->{ParsedTime} =~ m!^23:59!)
      {
	$enddate = present_ymd($cjdn + 1);
	$endtime = '01:00:00-08:00';
      }
    else
      {
	my($h, $m, $s) = split(/:/, $m->{ParsedTime});
	$h++;
	if($h == 24)
	  {
	    $h = 23;
	    $m = 59;
	  }
	$endtime = sprintf("%02d:%02d:%02d-08:00", $h, $m, $s);
	$enddate = $startdate;
      }
#	$enddate = present_ymd($cjdn + 1);


    my $startDateTime = $startdate . 'T' . $starttime;
#    $startDateTime = $startdate;
    my $endDateTime = $enddate . 'T' . $endtime;
#    $endDateTime = $enddate;
    my(%event) = ('summary' => $m->{Name}, 'location' => $m->{Address},
#		  'attendees' => [{email => 'kay.elearning@gmail.com' } ],
 'start' => { 'dateTime' => $startDateTime, "timeZone"=> "America/Los_Angeles" },
		 'end' => { 'dateTime' => $endDateTime, "timeZone"=> "America/Los_Angeles" } ,
		  'recurrence' => ['RRULE:FREQ=WEEKLY;COUNT=52'] 
);
    
    my $x = encode_json(\%event);
#    $x = encode_json({});
    
    $request = new HTTP::Request 'POST' => $url;
    $request->header('Authorization', 'Bearer ' . $d->{access_token});
    $request->header('Content-type', "application/json");
    $request->header('Content-length', length($x));
    $request->content($x);
    print $request->as_string;
    $response = $ua->request($request);
    print $response->as_string;
  }
