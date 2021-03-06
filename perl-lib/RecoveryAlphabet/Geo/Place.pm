package RecoveryAlphabet::Geo::Place;

use strict;
use vars qw(@ISA);

@ISA = qw(RecoveryAlphabet::Geo::Point);

sub new {
    my $class = shift;
    my($self) = { @_ };
    bless $self, $class;
}

sub latitude { shift->{INTPTLAT}; }
sub longitude { shift->{INTPTLONG} }
 
1;

