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
use Data::Dumper;

my $admin_username    = $ENV{ISPCONFIG_ADMIN_USERNAME};
my $admin_password    = $ENV{ISPCONFIG_ADMIN_PASSWORD};
my $host              = $ENV{ISPCONFIG_HOST};
my $default_password  = $ENV{DEFAULT_PASSWORD};

my $ua  = Mojo::UserAgent->new;

IO::Socket::SSL::set_defaults(SSL_verify_mode => SSL_VERIFY_NONE);

my $csv = Mojo::CSV->new( in => 'isp_etu.csv' );

ispconfig_login($ua);

my $global_id = ispconfig_next_clientid($ua);

while ( my $row = $csv->row ) {
  my ($nom, $prenom, $username, $email, $numero) = split(/;/, @$row[0]);
  next unless $nom && $prenom && $username && $email && $numero;

  my $res = $ua->get('https://'.$host."/client/client_edit.php")->result;

  sleep(2);

  print '$nom       = '.$nom."\n";
  print '$prenom    = '.$prenom."\n";
  print '$username  = '.$username."\n";
  print '$email     = '.$email."\n";

  $numero = $global_id;

  my $csrf_id     = Mojo::DOM->new($res->body)->find('input[name="_csrf_id"]')->first->attr('value');
  my $csrf_key    = Mojo::DOM->new($res->body)->find('input[name="_csrf_key"]')->first->attr('value');
  my $phpsessid   = Mojo::DOM->new($res->body)->find('input[name="phpsessid"]')->first->attr('value');

  my $tx = $ua->post('https://'.$host.'/client/client_edit.php' => {
    'Host'              => $host,
    'Origin'            => 'https://'.$host,
    'Referer'           => 'https://'.$host.'/login/',
  } => form => {
    company_name          => '',
    gender                => '',
    contact_firstname     => $prenom,
    contact_name          => $nom,
    customer_no           => 'ETU-'.$numero,
    customer_no_org       => 'ETU-'.$numero,
    username              => $username,
    password              => $default_password,
    repeat_password       => $default_password,
    language              => 'fr',
    usertheme             => 'default',
    street                => '',
    zip                   => '',
    city                  => '',
    state                 => '',
    country               => 'FR',
    telephone             => '',
    mobile                => '',
    fax                   => '',
    email                 => $email,
    internet              => 'https"%"3A"%"2F"%"2F',
    icq                   => '',
    vat_id                => '',
    company_id            => '',
    bank_account_owner    => '',
    bank_account_number   => '',
    bank_code             => '',
    bank_name             => '',
    bank_account_iban     => '',
    bank_account_swift    => '',
    paypal_email          => '',
    added_date            => '04-03-2022',
    added_by              => 'admin',
    notes                 => '',
    id                    => '',
    _csrf_id              => $csrf_id,
    _csrf_key             => $csrf_key,
    next_tab              => 'limits',
    phpsessid             => $phpsessid
  });

  sleep (2);

  my $html = $tx->result->body;

  $csrf_id      = Mojo::DOM->new($html)->find('input[name="_csrf_id"]')->first->attr('value');
  $csrf_key     = Mojo::DOM->new($html)->find('input[name="_csrf_key"]')->first->attr('value');
  $phpsessid    = Mojo::DOM->new($html)->find('input[name="phpsessid"]')->first->attr('value');
  my $id        = Mojo::DOM->new($html)->find('input[name="id"]')->first->attr('value');

  print 'Created client id '.$id."\n";

  my $tx2 = $ua->post('https://'.$host.'/client/client_edit.php' => {
  'Host'              => $host,
  'Origin'            => 'https://'.$host,
  'Referer'           => 'https://'.$host.'/login/',
  } => form => {
    template_master             => '1',
    template_additional         => '',
    parent_client_id            => '0',
    'web_servers[]'             => '1',
    limit_web_domain            => '10',
    limit_web_quota             => '2000',
    limit_traffic_quota         => '2000',
    'web_php_options[]'         => 'php-fpm',
    force_suexec                => 'y',
    limit_wildcard              => 'y',
    limit_web_aliasdomain       => '-1',
    limit_web_subdomain         => '-1',
    limit_ftp_user              => '0',
    limit_shell_user            => '10',
    'ssh_chroot[]'              => 'jailkit',
    limit_webdav_user           => '0',
    limit_backup                => 'y',
    limit_maildomain            => '0',
    limit_mailbox               => '0',
    limit_mailalias             => '0',
    limit_mailaliasdomain       => '0',
    limit_mailmailinglist       => '0',
    limit_mailforward           => '0',
    limit_mailcatchall          => '0',
    limit_mailrouting           => '0',
    limit_mail_wblist           => '0',
    limit_mailfilter            => '0',
    limit_fetchmail             => '0',
    limit_mailquota             => '0',
    limit_spamfilter_wblist     => '0',
    limit_spamfilter_user       => '0',
    limit_spamfilter_policy     => '0',
    limit_mail_backup           => 'y',
    limit_xmpp_domain           => '0',
    limit_xmpp_user             => '0',
    'db_servers[]'              => '1',
    limit_database              => '10',
    limit_database_user         => '10',
    limit_database_quota        => '500',
    limit_cron                  => '5',
    limit_cron_type             => 'url',
    limit_cron_frequency        => '5',
    'dns_servers[]'             => '1',
    limit_dns_zone              => '1',
    default_slave_dnsserver     => '1',
    limit_dns_slave_zone        => '1',
    limit_dns_record            => '20',
    limit_openvz_vm             => '0',
    limit_openvz_vm_template_id => '1',
    id                          => $id,
    _csrf_id                    => $csrf_id,
    _csrf_key                   => $csrf_key,
    next_tab                    => '',
    phpsessid                   => $phpsessid
  });

  print 'DONE '."\n";

  sleep (2);

  $global_id++;

}

exit;


sub ispconfig_login {
	my ($ua) = @_;

  print "Login in ispconfig with admin\n";

  my $res = $ua->get('https://'.$host."/login/")->result;

  sleep(1);

  my $tx = $ua->post('https://'.$host.'/login/index.php' => {
    'Host'              => $host,
    'Origin'            => 'https://'.$host,
    'Referer'           => 'https://'.$host.'/login/',
  } => form => {
    username  => $admin_username,
    password  => $admin_password,
    s_mod     => 'login',
    s_pg      => 'index',
  });

  sleep(1);

}

sub ispconfig_next_clientid {
	my ($ua) = @_;

  print "Get last id ";

  # bah
  $ua->post('https://'.$host.'/client/client_list.php?orderby=client_id' => {
    'Host'              => $host,
    'Origin'            => 'https://'.$host,
    'Referer'           => 'https://'.$host.'/login/',
  } => form => {
    search_limit          => '1',
  });

  # oui
  my $tx = $ua->post('https://'.$host.'/client/client_list.php?orderby=client_id' => {
    'Host'              => $host,
    'Origin'            => 'https://'.$host,
    'Referer'           => 'https://'.$host.'/login/',
  } => form => {
    search_limit          => '1',
  });

  my $html = $tx->result->body;

  my ($prefix, $client_id) = split(/-/, Mojo::DOM->new($html)->find('tbody tr td')->to_array->[4]->all_text);
  
  $client_id++;

  return $client_id;


}

1;

