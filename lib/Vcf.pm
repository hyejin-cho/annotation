package lib::Vcf;
use strict;
use warnings; 


sub new {
   my $class = shift;
   my $line = shift;

   my @content = split/\t/, $line;
   

   my $self = { 
      CHROM => $content[0],
      POS => $content[1],
      REF => $content[3],
      ALT => [ split(/,/,$content[4]) ], 
      INFO => $content[7],
      FORMAT=> $content[8],
      FVAL=> $content[9],   
   };

   bless $self, $class;

   #set values
   $self->_parse_line(); 

   return $self;
}

sub _parse_line {
   my $self = shift;
      
   #get annotation and ALT
   die "No annotation." unless defined $self->{INFO};
   
   for my $info (split(/;/, $self->{INFO})) {
      my ($key,$val) = split/=/,$info;
     
      #only need Annotation info from Snpeff
      next unless $key eq 'ANN'; 

      #Snpeff reports multiple annotations separated by comma
      #Snpeff sorts multiple annotations by 'deleteriousness'. Most deleterious one is needed only.
      my @arr = split(/\|/, (split(/\,/, $val))[0]);
      
      #print STDERR "check ann: ", $arr[0], ",", $arr[1], "\n";
      $self->{ALT_MD} = $arr[0];
      $self->{ANN} = $arr[1];

   }

   #get genotype through parsing format field.
   #print STDERR "self format:", $self->{FORMAT},", ", $self->{FVAL}, "\n";
   die "No values for genotype Format field." if($self->{FVAL} eq ''); 
   
   my @keys =  split/:/, $self->{FORMAT};
   my @vals =  split/:/, $self->{FVAL};

   die "Format fields and values are not matched." unless @keys == @vals;

   my %gtypes;

   for(my $i=0; $i<@keys;$i++) {
      $gtypes{$keys[$i]} = $vals[$i];
   }

   $self->{GTYPE} = \%gtypes;
}

1;

