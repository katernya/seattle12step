# -*- cperl -*-
package RecoveryAlphabet::Geo::Places;

use strict;
require RecoveryAlphabet::Geo::Place;
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
      push @{$self->{_places}}, \@row;
      my $name = $row[$self->{_headerIndex}->{NAME}];
      my(%place);
@place{@headerfields} = @row;
      my $place = new RecoveryAlphabet::Geo::Place(%place);
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
      

1;
