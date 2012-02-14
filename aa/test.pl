#!/usr/bin/perl

unshift @INC, "../perl-lib";

require RecoveryAlphabet::Geo::Places;
require RecoveryAlphabet::Geo::Zips;
$places = new RecoveryAlphabet::Geo::Places();
$zips = new RecoveryAlphabet::Geo::Zips();

my $seattle = $places->getPlaceByName("Seattle");
print join(", ", map($_->{GEOID}, ($zips->within_radius_of(2, $seattle)))), "\n";



