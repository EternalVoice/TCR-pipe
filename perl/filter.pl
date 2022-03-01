#!/usr/bin/perl -w
use strict;

open IN , $ARGV[0] || die;
while (<IN>){
chomp;
if (/^clone/) {print "$_\n"; next;}
my @ar = split /\t/;
#print "$_\n@ar\n\n";
#print "$ar[6]\n";die;
next if ($ar[-3] =~ /\*/ || $ar[-3] =~ /_/);
next if (length ($ar[-3]) < 4); 
print "$_\n";
}
