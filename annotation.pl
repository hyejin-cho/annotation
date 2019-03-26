#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long; 
use lib::Vcf;
use lib::ExAC;
use POSIX qw(strftime);

my $usage = <<"USAGE";
usage: $0 vcf;
USAGE

die $usage unless @ARGV == 1;


my $exac_url = "http://exac.hms.harvard.edu/rest/variant/variant/";

#run snpEff
open OUTPUT, "java -Xmx128g -jar ../snpEff_latest_core/snpEff/snpEff.jar GRCh37.75 $ARGV[0] |";

process();
 
sub process {

my $flag = 0;
my $added = 0;

   while (<OUTPUT>) {
      chomp;
      
      if (/^##/) { #comments line, add my own into INFO field
        #change date to Today
        
        $flag = 1 if /^##SnpEff/; #remove SnpEff comment and add mine.        
        
        if($flag == 0) { #standard comment
           if(/^##fileDate/){ #change Date to Today
              my $date = strftime "%m/%d/%Y", localtime;
              print "##fileDate=$date\n";
           }else{
              print "$_\n";           
           }
      
        }else{
           next if $added;
           print "##Variant Annotation Tool by Hyejin Cho\n";
           print "##Annotation command=\"perl annotation.pl input.vcf > output.vcf\"\n";
           print "##INFO=<ID=ANNO,Number=.,Type=String,Description=\"Functional annotations: \'Annotation_Type | Sequence_Depth | Number of Reads for the variant | Percentage of reads for the variant, Percentage of reads for the reference | Allele frequency of variant from ExAC | Optional information from ExAC (vep_annotation-major consequence)\' \">\n";
          $added = 1;           
        }
        next;
      }elsif (/^#/) { #header
         print "$_\n";
         next;
      }
   
      ##parse each line of vcf for annotation
      my $vcf = lib::Vcf->new($_);
      
      my @fields = split/\t/;

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
      my $anno=join("|", ($ann, $dp, $ao, $p_ao.'/'.$p_ro, $freq, $opt));
      $vcf->remove_info_id('ANN'); #remove annotation from SnpEff
      my $info = $vcf->add_info_field('ANNO', $anno);
      
      #replace info field 
      $fields[7] = $info;
      
      print join("\t", @fields), "\n";      
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
