package RecoveryAlphabet::Geo::Config;

require Exporter;

@::ISA = qw(Exporter);
@::EXPORT_OK = qw($GeoFilePath);

$::GeoFilePath = '../data-dist';

1;
