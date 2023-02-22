#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use utf8;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use Data::Dumper;
use Mojo::DOM;
use Mojo::UserAgent;
use Mojo::JSON qw(to_json from_json decode_json encode_json);
use POSIX qw/strftime/;
use Mojo::CSV;


my $admin_username      = $ENV{JENKINS_ADMIN_USERNAME};
my $jenkins_host        = $ENV{JENKINS_HOST};
my $jenkins_ssh_port    = $ENV{JENKINS_SSH_PORT};
my $default_password    = $ENV{DEFAULT_PASSWORD};

die "Variables d'environement manquantes \n" unless $admin_username && $jenkins_host && $jenkins_ssh_port;

my $csv = Mojo::CSV->new( in => 'isp_etu.csv' );


while ( my $row = $csv->row ) {
  my ($nom, $prenom, $username, $email, $numero) = split(/;/, @$row[0]);
  next unless $nom && $prenom && $username && $email && $numero;

  sleep(2);

  print '$nom       = '.$nom."\n";
  print '$prenom    = '.$prenom."\n";
  print '$username  = '.$username."\n";
  print '$email     = '.$email."\n";

  my $groovy = "cat groovy/user-creation.groovy | 
  ssh -l ".$admin_username." -p ".$jenkins_ssh_port." ".$jenkins_host." groovy = ".$username." ".$default_password." ".$email." ";

  system($groovy);


}


