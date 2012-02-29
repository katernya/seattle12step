package Seattle12Step::Config;

use strict;

#use AutoLoader;
require Exporter;
require FileHandle;
use JSON;
use vars qw(@ISA @EXPORT_OK %Config);

@ISA = qw(Exporter);
@EXPORT_OK = qw(WebAppsClientId WebAppsRedirectUri);

sub INIT {
  my $fh = new FileHandle '../config/google-api.json';
  $Config{googleapi} = decode_json(join('', $fh->getlines()));
  $fh->close();
}

sub WebAppsClientId { $Config{googleapi}{clients}{webapps}{clientId} }
sub WebAppsRedirectUri { $Config{googleapi}{clients}{webapps}{redirectUris}[0] }
1;
