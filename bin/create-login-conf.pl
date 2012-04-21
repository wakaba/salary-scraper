#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(getcwd);
use MIME::Base64 qw(encode_base64);

print STDERR "Name: ";
my $Name = <STDIN>;
chomp $Name;
$Name = encode_base64 $Name;
chomp $Name;

print STDERR "Password: ";
my $Password = <STDIN>;
chomp $Password;
$Password = encode_base64 $Password;
chomp $Password;

print STDERR "Login URL: ";
my $LoginURL = <STDIN>;
chomp $LoginURL;

print STDERR "Data directory: ";
my $DataDirName = <STDIN>;
chomp $DataDirName;
$DataDirName = getcwd . q</> . $DataDirName;

print join "\n", $Name, $Password, $LoginURL, $DataDirName;

=head1 NAME

create-login-conf.pl - Create login configuration file for salary-scraper

=head1 SYNOPSIS

  $ perl bin/create-login-conf.pl > config/login.conf

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
