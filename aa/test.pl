#!/usr/bin/perl

unshift @INC, "../perl-lib";

require RecoveryAlphabet::Geo::Places;
$places = new RecoveryAlphabet::Geo::Places();
my $seattle = $places->getPlaceByName("Seattle");
print $seattle->longitude(), "\n";


