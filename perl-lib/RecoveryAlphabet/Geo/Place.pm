package RecoveryAlphabet::Geo::Place;

sub new {
    my $class = shift;
    my($self) = { @_ };
    bless $self, $class;
}

sub latitude { shift->{INTPTLAT}; }
sub longitude { shift->{INTPTLONG} }
 
1;

