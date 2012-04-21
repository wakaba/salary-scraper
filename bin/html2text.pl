#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;

my $dir_name = shift;
my $d = dir ($dir_name);

my $parse_script_name = file (__FILE__)->dir->file ('parse-table.pl')->stringify;

$d->recurse (callback => sub {
  my $f = $_[0];
  return unless $f =~ /\.html\.sjis$/;
  my $text_file_name = $f->stringify;
  $text_file_name =~ s/\.html\.sjis$/.txt/g;
  
  system 'perl ' . (quotemeta $parse_script_name) .
      ' < ' . (quotemeta $f) .
      ' > ' . (quotemeta $text_file_name);
});

=head1 NAME

html2text.pl - Extract salary data from HTML files

=head1 SYNOPSIS

  $ perl bin/html2text.pl data-directory

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
