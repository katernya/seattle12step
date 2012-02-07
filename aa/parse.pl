
sub parseaddress {
    my $add = shift @_;
    $add =~ s!\(.*\)!!s;
    my $zip;
    if($add =~ s!(\D{3})(98\d\d\d)!\1!)
      {
	$zip = $2;
      }

    if($add =~ /(\d+)(?:-|\s+)(?:(N|E|S|W|NE|NW|SE|SW)\.?\s+)?(\S+(?:\s+\S{4,})?)(?:\s+(St|Street|Wy|Way|Ave|Avenue|Dr|Drive|Hwy|Highway|Blvd|rd|Road))?(?:\s+(NE|NW|SE|SW|N|E|S|W)\.?)?/i)
{
    ([$1, $2, $3, $4, $5], $city, $zip);
}
else
{
    undef;
}
}
1;
