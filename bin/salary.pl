#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
BEGIN {
  my $libs_file_name = dirname __FILE__;
  $libs_file_name .= '/../config/perl/libs.txt';
  if (-f $libs_file_name) {
    local $/ = undef;
    open my $libs_file, '<', $libs_file_name or die "$libs_file_name: $!";
    unshift @INC, split /:/, <$libs_file>;
  }
}
use Path::Class;
use lib glob file (__FILE__)->dir->parent->subdir ('modules', '*', 'lib')->stringify;
use Encode qw(encode decode);
use URL::PercentEncode qw(percent_encode_b);
use Web::UserAgent::Functions qw(http_get http_post_data);
use Message::DOM::DOMImplementation;
use MIME::Base64 qw(decode_base64);

my $config_f = file (shift);
my ($Name, $Password, $LoginURL, $DataDirName) = ($config_f->slurp);
$Name = decode 'utf-8', decode_base64 $Name;
$Password = decode 'utf-8', decode_base64 $Password;
my $DataD = dir ($DataDirName);

use utf8;
binmode STDOUT, qw(:encoding(utf-8));
binmode STDERR, qw(:encoding(utf-8));
$Web::UserAgent::Functions::MaxRedirect = 0;

my $dom = Message::DOM::DOMImplementation->new;
my $Charset = 'windows-31j';
my $Origin;
$Origin = $1 if $LoginURL =~ m{^([^:/]+://[^/]+)}
    or die "Login URL is invalid";

our $Doc = $dom->create_document;
$Doc->manakai_is_html (1);
my $Cookies = {};

sub get_html ($$) {
  my ($referer => $url) = @_;
  $url =~ m{^\Q$Origin/\E} or die "URL <$url>'s origin is not <$Origin>";
  sleep 1;
  my (undef, $res) = http_get
      url => $url,
      header_fields => {Referer => $referer},
      cookies => $Cookies;
  unless ($res->is_success) {
    die "Can't retrieve page " . $url;
  }

  $Doc->document_uri ($url);
  $Doc->inner_html (decode $Charset, $res->content);
} # get_html

sub login () {
  get_html $LoginURL => $LoginURL;
  my $form = $Doc->query_selector ('form') or die "Login form not found";
  my $controls = $form->query_selector_all ('input');
  my $data_set = [];
  for (@$controls) {
    my $name = $_->get_attribute ('name') or next;
    my $value = $_->get_attribute ('value') // '';
    push @$data_set, [$name => $value];
  }
  die "Login form has too few controls" unless @$data_set > 2;
  
  $data_set->[0]->[1] = $Name;
  $data_set->[1]->[1] = $Password;
  
  my $post_url = $form->get_attribute ('action') 
      or die "Login form has no |action|";
  
  #$post_url =~ m{^\Q$Origin/\E}
  #    or die "URL <$post_url>'s origin is not <$Origin>";
  sleep 1;
  my (undef, $res) = http_post_data
      url => $post_url,
      header_fields => {
          'Content-Type' => 'application/x-www-form-urlencoded',
          Referer => $LoginURL,
      },
      content => (join '&', map {
        (percent_encode_b encode $Charset, $_->[0])
        . '=' .
        (percent_encode_b encode $Charset, $_->[1])
      } @$data_set);
  
  my $set_cookies = [($res->header ('Set-Cookie'))];
  for (@$set_cookies) {
    if (/^\s*([^\s;=]+)=([^;]+);/) {
      $Cookies->{$1} = $2;
    }
  }

  my $menu_url = $res->header ('Location') or die "Login failed";
  $Origin = $1 if $menu_url =~ m{^([^:/]+://[^/]+)}
      or die "Login redirect URL is invalid";
  return $menu_url;
} # login

sub extract_month_links ($$) {
  my ($referer => $url) = @_;
  
  get_html $referer => $url;

  my $month_pages = $Doc->query_selector_all
      ('a:-manakai-contains("年"):-manakai-contains("月")');
  my $month_links = [grep {
    $_->[1] =~ s/^([0-9]{4})年([0-9]{1,2})月$/sprintf '%04d-%02d', $1, $2/ge;
  } map {
    [$_->href, $_->text_content]
  } @$month_pages];
  
  my $next_pages = $Doc->query_selector_all ('.smp-page a');
  my $next_urls = [map { $_->href } @$next_pages];

  return ($month_links, $next_urls);
} # extract_month_links

sub get_download ($$$) {
  my ($referer => $url => $f) = @_;
  $url =~ m{^\Q$Origin/\E} or die "URL <$url>'s origin is not <$Origin>";
  sleep 1;
  my (undef, $res) = http_get
      url => $url,
      header_fields => {Referer => $referer},
      cookies => $Cookies;
  die "Can't download page " . $url unless $res->is_success;

  warn $f, "\n";
  my $file = $f->openw;
  print $file $res->content;
} # get_download

my $menu_url = login;
get_html $LoginURL => $menu_url;

for my $rule (
  {
    id => 'salary',
    selectors => 'a:-manakai-contains("給与明細")',
  },
  {
    id => 'bonus',
    selectors => 'a:-manakai-contains("賞与明細")',
  },
) {
  my $a_el = $Doc->query_selector ($rule->{selectors})
      or die "List page link not found in menu page";
  my $list_url = $a_el->href or die "List page link not found in menu page";
  
  local $Doc = $dom->create_document;
  $Doc->manakai_is_html (1);

  my ($month_links, $next_urls) = extract_month_links $menu_url => $list_url;
  for (@$next_urls) {
    my ($m, undef) = extract_month_links $menu_url => $_;
    push @$month_links, @$m;
  }

  my $month_found = {};
  for (@$month_links) {
    if ($month_found->{$_->[1]}++) {
      $_->[1] .= '-' . $month_found->{$_->[1]};
    }
  }

  $DataD->subdir ($rule->{id})->mkpath;
  for (@$month_links) {
    my $f = $DataD->subdir ($rule->{id})->file ($_->[1] . '.html.sjis');
    get_download $menu_url => $_->[0] => $f;
  }
}

=head1 NAME

salary.pl - Save salary data HTML files

=head1 SYNOPSIS

  $ perl bin/salary.pl config/login.conf

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
