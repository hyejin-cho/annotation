#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long; 
use lib::Vcf;
use lib::ExAC;

my $usage = <<"USAGE";
usage: $0 vcf;
USAGE

die $usage unless @ARGV == 1;

my $exac_url = "http://exac.hms.harvard.edu/rest/variant/variant/";

#print head
print join("\t", ("Type","Read Depth", "# of reads", "% Ref/% Alt", "Freq", "Opt")),"\n";

#run snpEff
open OUTPUT, "java -Xmx128g -jar ../snpEff_latest_core/snpEff/snpEff.jar GRCh37.75 $ARGV[0] |";

process();
 
sub process {
   while (<OUTPUT>) {
      chomp;
      next if /^#/; #skip the comment line
   
      ##parse each line of vcf
      my $vcf = lib::Vcf->new($_);
      
      #get chosed alternate allele (most deleterious one)position
      my $pos = get_alternate_pos($vcf->{ALT}, $vcf->{ALT_MD});
      #get DP and AO column location
      my $dp = $vcf->{GTYPE}{'DP'};
      my $ao = (split('\,', $vcf->{GTYPE}{'AO'}))[$pos];
      my $ro = $vcf->{GTYPE}{'RO'};
      my $p_ao = $ao==0?0:$ao/$dp;
      my $p_ro = $ro==0?0:$ro/$dp;
      my $ann = $vcf->{ANN};

      ##get allele frequency of variant from Broad Institute ExAC Project API
      my $url = $exac_url.join("-", ($vcf->{CHROM},$vcf->{POS}, $vcf->{REF}, $vcf->{ALT_MD}));
      my $exac = lib::ExAC->new($url);
      
 
      #get freqeuncy
      my $freq = $exac->{is_success} eq "Y"?$exac->get_hash_val('allele_freq'):'N/A';
      
      #get optional information
      my $opt = $exac->{is_success} eq "Y"?$exac->get_hash_of_hash('vep_annotations','major_consequence'):'N/A';
      $opt='N/A' unless defined $opt; 
#print output
      print join("\t", ($ann, $dp, $ao, $p_ao.'/'.$p_ro, $freq, $opt)), "\n";
   }
   close(OUTPUT);
}

sub get_alternate_pos {

   my ($alt_arr, $alt_chosed) = @_;
   my @arr = @{ $alt_arr };
   return 0 if @arr == 1; #not multiple alternate allele
   my $pos  = 0;
   for(@arr) {
      return $pos if $_ eq $alt_chosed; 
      $pos++;
   }

}
