#!/usr/bin/perl
#
# Tweaked version of text2html, from
# From http://peter.verhas.com/progs/perl/text2html/
# --------------------------------------------------
#
# LEGAL WARNING:
#
# This software is provided on an "AS IS", basis,
# without warranty of any kind, including without
# limitation the warranties of merchantability, fitness for
# a particular purpose and non-infringement. The entire
# risk as to the quality and performance of the Software is
# borne by you. Should the Software prove defective, you
# and not the author assume the entire cost of any service
# and repair.
#

# text2html.pm
use text2html;

$InputFile = shift;

die "Can not read-open $InputFile" unless open(IN,"<$InputFile");

$OutputFile = shift;

if( defined($OutputFile) ){
  $out = $OutputFile;
  die "Can not write-open $OutputFile" unless open($out,">$OutputFile");
  }else{
  $out = \*STDOUT;
  }
undef $/;
$Text = <IN>;
close IN;

#  
# Convert a text heuristically to HTML
# input is the pointer the text. The text itself is destroyed.
# output is the pointer to the HTML text
#
# the second optional argument is a string containing nl separated options, like
#  
# NOHEAD do not generate head and tail (<HTML><HEAD> ... and </BODY></HTML>)
# NOTOC  do not generate table of contents
# FONTSIZE specify the size of the font, like FONTSIZE=2
# FONTFACE specify font face, like FONTFACE=Verdana
# PRESTART how to start a <pre> section, like <FONT SIZE=3><PRE>
# PREEND   how to end a </pre> section, like </PRE></FONT>

$ptrText = &text2html(\$Text, <<END
FONTFACE=Arial, Helvetica, sans-serif
FONTSIZE=3
PRESTART=<ul><FONT SIZE=3><PRE>
PREEND=</PRE></FONT></ul>
TTSTART=
TTEND=
END
);

#NOTOC
#TTSTART=<FONT SIZE=3><TT>
#TTEND=</TT></FONT>

print $out $$ptrText;
exit;

