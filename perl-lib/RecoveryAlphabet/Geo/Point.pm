package RecoveryAlphabet::Geo::Point;

sub new {
    my $class = shift;
    my $lat = shift;
    my $long = shift;
    my $self = { _latitude => $lat, _longitude => $long };
    bless $self, $class;
}

sub latitude { shift->{_latitude} }
sub longitude { shift->{_longitude} }
1;
