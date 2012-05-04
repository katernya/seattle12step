package RecoveryAlphabet::Geo::Zips;

require RecoveryAlphabet::Geo::Zip;
use RecoveryAlphabet::Geo::Config qw($GeoFilePath);

use Math::Trig;

require FileHandle;

sub getZipByCode {
  my $self = shift;
  my $code = shift;
  $self->{_zipsByCode}{$code};
}


sub new {
  my $class = shift;
  my $self = {};
  $self = bless $self, $class;
  $self->load_zips();
  $self;
}

sub load_zips {
  my $self = shift;
  my $fh = new FileHandle $::GeoFilePath . '/' . 'Gaz_zcta_national.txt';
  die $! unless $fh;

  my $headerline = $fh->getline();
  chomp($headerline);
  my(@headerfields) = split(/\t/, $headerline);

  grep($self->{_headerIndex}->{$headerfields[$_]} = $_, 0..$#headerfields);

  $self->{_zips} = [];
  $self->{_zipsByCode} = {};

  while(my $line = $fh->getline())
    {
      chomp($line);
      my(@row) = split(/\t/, $line);
      my $code = $row[$self->{_headerIndex}->{GEOID}];
      my(%zip);
      @zip{@headerfields} = @row;
      my $zip = new RecoveryAlphabet::Geo::Zip(%zip);
      push @{$self->{_zips}}, $zip;
      $self->{_zipsByCode}->{$code} = $zip;
    }
  $fh->close();
}

sub within_radius_of
    {
      my $self = shift;
      my $radius = shift;
      my $point = shift;
      grep($self->distance_between($point, $_) < $radius, @{$self->{_zips}});
    }


sub distance_between
{
  my $self = shift;
  my $place1 = shift;
  my $place2 = shift;
  die unless ref $place1 && ref $place2;
  &Haversine($place1->latitude, $place1->longitude, $place2->latitude, $place2->longitude);
}

sub Haversine {
    my ($lat1, $long1, $lat2, $long2) = @_;
    my $r=3956;

               
    my $dlong = deg2rad($long1) - deg2rad($long2);
    my $dlat  = deg2rad($lat1) - deg2rad($lat2);

    my $a = sin($dlat/2)**2 +cos(deg2rad($lat1)) 
                    * cos(deg2rad($lat2))
                    * sin($dlong/2)**2;
    my $c = 2 * (asin(sqrt($a)));
    my $dist = $r * $c;               


    return $dist;

}

1;
