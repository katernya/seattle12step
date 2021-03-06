# -*- cperl -*-
package RecoveryAlphabet::Geo::Places;

use strict;
require RecoveryAlphabet::Geo::Place;
require RecoveryAlphabet::Geo::Points;
use Math::Trig;
use RecoveryAlphabet::Geo::Config qw($GeoFilePath);

require FileHandle;

sub new {
  my $class = shift;
  my $self = {};
  $self = bless $self, $class;
  $self->load_places();
  $self;
}

sub load_places {
  my $self = shift;
  my $fh = new FileHandle $::GeoFilePath . '/' . 'Gaz_places_53.txt';
  die $! unless $fh;

  my $headerline = $fh->getline();
  chomp($headerline);
  my(@headerfields) = split(/\t/, $headerline);

  grep($self->{_headerIndex}->{$headerfields[$_]} = $_, 0..$#headerfields);

  $self->{_places} = [];
  $self->{_placesByUntypedName} = {};

  while(my $line = $fh->getline())
    {
      chomp($line);
      my(@row) = split(/\t/, $line);
      my $name = $row[$self->{_headerIndex}->{NAME}];
      my(%place);
@place{@headerfields} = @row;
      my $place = new RecoveryAlphabet::Geo::Place(%place);
      push @{$self->{_places}}, $place;
      # remove terminating place type
      $name =~ s/\s+\w+$//;
      $self->{_placesByName}->{$name} = $place;
    }
  $fh->close();
}

sub getPlaceByName
  {
    my $self = shift;
    my $name = shift;
    $self->{_placesByName}{$name};
  }
      

sub within_radius_of
    {
      my $self = shift;
      my $radius = shift;
      my $place = $self->get_place(shift);
      die unless ref $place;
      grep($self->distance_between($place, $_) < $radius, @{$self->{_places}});
    }

sub get_place
      {
	my $self = shift;
	my $placeId = shift;
	my $place;
	$place = $self->{_placesByName}{$placeId};
	if($place)
	  {
	    return $place;
	  }
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
