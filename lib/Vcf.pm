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

sub remove_info_id {
   my $self = shift;
   my $id = shift;
   
   my $line='';
   for my $info (split(/;/, $self->{INFO})) {
      my ($key,$val) = split/=/,$info;

      #remove field if ID is matched with given $id
      $line .= $info.";" unless $id eq $key;
   }
   $self->{INFO} = $line; #replace after removal
   return $self;
}

sub add_info_field {
   my $self=shift;
   my $add_key = shift;
   my $add_val = shift;
   $self->{INFO} .= $add_key."=".$add_val;
  
   return $self->{INFO};
}

1;

