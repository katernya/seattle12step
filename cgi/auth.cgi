#!/usr/local/ActivePerl-5.14/bin/perl

require CGI;
require LWP::UserAgent;
require URI::URL;
use Seattle12Step::Config qw(WebAppsClientId);

my $ua = new LWP::UserAgent;

my $q = CGI->new();
my $url = new URI::URL 'https://accounts.google.com/o/oauth2/auth';
$url->query_form(response_type => 'code',
		 client_id => &WebAppsClientId,
		 redirect_uri => &WebAppsRedirectUri,
		 access_type => offline,
		 approval_prompt => 'auto',
		 'scope' => 'https://www.googleapis.com/auth/calendar');
print "Location: ", $url->as_string(), "\n\n";
