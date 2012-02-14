#!/usr/bin/perl

use JSON;
open(OUT, "out.txt");
$out = join('', <OUT>);
$a = decode_json($out);
print join("\n", map($_->{LocationName}, @{$a}));
#print join("\n", map(join($;, @{$_->{LocationParts}}), @{$a}));
