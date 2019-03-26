#!/usr/bin/perl -w
use strict;
use warnings; 

#use LWP::Simple;                # From CPAN
use LWP::UserAgent;
use JSON qw( decode_json );     # From CPAN
use Data::Dumper

my $ua = LWP::UserAgent->new;

#my $url = "http://exac.hms.harvard.edu/rest/variant/variant/1-935222-C-A";

#my $url = "http://exac.hms.harvard.edu/rest/variant/variant/1_931393-G-T";

my $url = $ARGV[0];
my $resp = $ua->get($url);
print STDERR "rlt:", $resp->is_success,"\n";
die $resp->status_line unless $resp->is_success;

# Decode the entire JSON
my $json = $resp->decoded_content;
my $decoded = decode_json( $json );
my $anno = @{ $decoded->{'vep_annotations'} }[0]; #first one
my $temp = "N/A";
$temp = $decoded->{'allele_count'} if defined $decoded->{'allele_count'};
#print "freq = $temp\n";
#print "anno = ", $anno->{'major_consequence'}, "\n";

open OUT, ">test.txt";
# you'll get this (it'll print out); comment this when done.
print OUT Data::Dumper->Dump([$decoded],[qw(decoded)]);

