#!/usr/bin/env perl
use Modern::Perl '2013';
use Daud;

my @entries;

for my $raw_daud (Daud::_raw_data())
{
	next if $raw_daud =~ /^#/;
	my ($daud, $ascii, $unicode, $html, $name) = split(/;/, $raw_daud);
	push @entries, [ length($daud), join('', "<U", $unicode, "> ",
	    (map { "\\x".unpack('H2', $_) } ( '{', split(//, $daud), '}')),
	    " |0 # ", $name, "\n" ) ];
}
print map { $_->[1] } sort { $a->[0] <=> $b->[0] } @entries;
print "END CHARMAP\n";
