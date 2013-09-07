#!/usr/bin/perl

# Author: Olivier Mengué <dolmen@cpan.org>
# https://github.com/dolmen/
# License: same as Perl 5 (which is Artistic+GNU GPL)

use 5.010;
use strict;
use warnings;

use Unicode::Normalize;
use JSON;
use Encode;
use Getopt::Long;

my $check;
GetOptions('check|c' => \$check) or die "invalid arguments";

my $json = do { local $/; <> };

my $JSON = JSON->new->ascii->allow_nonref(1);
my $utf8 = Encode::find_encoding('utf-8');

sub fix_json_mojibake
{
    my $in = shift;
    my $out = eval { $utf8->decode(pack('(H2)*', $in =~ m{\\u00(..)}sg), 1) };
    return defined($out)
	? substr($JSON->encode(Unicode::Normalize::NFC($out)), 1, -1)
	: $in # TODO check that $in is properly encoded
}

$json =~ s/((?:\\u00..){2,})(?!\\u)/ fix_json_mojibake($1) /gse;

if ($check) {
    my $utf16 = Encode::find_encoding('UTF-16BE');
    while ($json =~ m/((?:\\u....)+)/g) {
	my $encoded = $1;
	# If the following line fails, the encoding is broken
	eval {
	    $utf16->decode(pack('(H4)*', $encoded =~ m{\\u(....)}sg, 1))
	} or die "invalid string: $encoded: $@"
    }
}

print $json;
