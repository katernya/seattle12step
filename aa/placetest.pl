unshift @INC, '../perl-lib';
require JSON;
require URI::URL;
require LWP::UserAgent;
require HTTP::Request;

require RecoveryAlphabet::Geo::Places;
my $places = new RecoveryAlphabet::Geo::Places();
$places->load_places();

my $ua = new LWP::UserAgent();
my $url = new URI::URL "https://maps.googleapis.com/maps/api/place/search/json";
$url->query_form(key => 'AIzaSyDOx6l9jZFmyR1pE2ZU62PXe-fSWHrnop4',
		 'location' => $places->getPlaceByName('Seattle')->latitude .','.
		 $places->getPlaceByName('Seattle')->longitude, radius => 80000, sensor => 'false', name => $location);
      my $req = new HTTP::Request('GET' => $url);
print $req->as_string();
      my $response = $ua->request($req);
print $response->content();
