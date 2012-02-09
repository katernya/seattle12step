# -*- cperl -*-
package RecoveryAlphabet::Geo::Places;

use RecoveryAlphabet::Geo::Config qw($GeoFilePath);

INIT { print STDERR $GeoFilePath , "\n"; }


1;
