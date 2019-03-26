package lib::ExAC;

use strict;
use warnings; 

use LWP::UserAgent;
use JSON qw( decode_json );     # From CPAN

sub new {
   my $class = shift;
   my $url = shift;
   
   my $ua = LWP::UserAgent->new;
   my $resp = $ua->get($url);
   my $decoded = decode_json($resp->decoded_content);
   my $rlt = defined $decoded->{'allele_count'}?"Y":"N";
   
   #print STDERR "rlt:",$resp->is_success,"|", $resp->status_line,"\n"; 
   
   my $self = {
      is_success=>$rlt,
      json_obj=>$decoded,
   };
   
   bless $self, $class;

   return $self;   
}

sub get_hash_val {
   my $self = shift;
   my $key = shift;
   my $obj = $self->{json_obj};

   return $obj -> {$key};
}

sub get_hash_of_hash { #additional optional information
   my $self = shift;
   my $first_key = shift;
   my $second_key = shift;

   my $obj = $self->{json_obj};
   my $value = @{ $obj->{$first_key} }[0]; #only the first one from array

   return $value->{$second_key};
}

1;
