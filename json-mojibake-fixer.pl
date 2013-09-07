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

print $json;
