#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->subdir ('modules', '*', 'lib')->stringify;
BEGIN {
  my $libs_f = file (__FILE__)->dir->parent->file ('config', 'perl', 'libs.txt');
  unshift @INC, split /:/, scalar $libs_f->slurp if -f $libs_f;
}
use Encode qw(encode decode);
use Message::DOM::DOMImplementation;
use Whatpm::HTML::Table;

binmode STDIN, qw(:encoding(windows-31j));
binmode STDOUT, qw(:encoding(utf-8));
binmode STDERR, qw(:encoding(utf-8));

my $dom = Message::DOM::DOMImplementation->new;
my $doc = $dom->create_document;
$doc->manakai_is_html (1);

local $/ = undef;
$doc->inner_html (<>);

my $table_els = $doc->query_selector_all ('table.tmplS');

for my $table_el (@$table_els) {
  my $table = Whatpm::HTML::Table->form_table ($table_el);

  my $caption = '';
  my $caption_el = $table_el->query_selector ('.head_title2');
  if ($caption_el) {
    $caption = $caption_el->text_content;
    $caption =~ s/\s+//g;
  }
  
  for my $x (0..$#{$table->{cell}}) {
    Y: for my $y (0..$#{$table->{cell}->[$x]}) {
      my $cell = $table->{cell}->[$x]->[$y] or next Y;
      $cell = $cell->[0] or next Y;
      my $el = $cell->{element} or next Y;

      $el->class_name =~ /\btitle2\b/ or next Y;
      $el->class_name =~ /\btitle2_sub\b/ and next Y;
      
      my $label = [$caption, $el->text_content];
      $label->[0] =~ s/[\s\xA0]+//;
      $label->[0] or next Y;

      my $diff = 1;
      DATA: {
        my $data_cell = $table->{cell}->[$x]->[$y + $diff] or next Y;
        $data_cell = $data_cell->[0] or next Y;
        my $data_el = $data_cell->{element} or next Y;
        
        if ($data_el->class_name =~ /\btitle2_sub\b/) {
          push @$label, $data_el->text_content;
          $label->[-1] =~ s/[\s\xA0]+//;
          $diff++;
          redo DATA;
        }
        
        $data_el->class_name =~ /\bdata\b/ or next Y;
        my $value = $data_el->text_content;
        $value =~ s/[\s\xA0]+//;
        next unless $value;

        print join '.', @$label;
        print "\t";
        print $value;
        print "\n";
      }
    }
  }
}

=head1 NAME

parse-table.pl - Extract salary data from an HTML file

=head1 SYNOPSIS

  $ perl bin/html2text.pl < 2012-04.html.sjis > 2012-04.txt

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
