#!/usr/bin/perl
#
# From http://peter.verhas.com/progs/perl/text2html/
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

package text2html;

require Exporter;
@ISA = Exporter;
@EXPORT = qw(text2html);

BEGIN {
  $MaximalNumberOfTitleLines = 3;
  @hrule = ( '-','/','=','_' );
  $bullet_regexp = 'o|\-|\*|\+';
  $nobullet_regexp = 'a|A|e|E|i|I';  # characters that can not be bullets
  #$allcapsheader = '^\s*[A-Z][^a-z]*\s*$';
  $allcapsheader = '^\s*[A-Z0-9][^a-z]*\s*$';

  #
  # Lines that are shorter than $MaximalLineLength/$ShortLineRatio are not taken
  # into account when the average line length is calculated.
  #
  $ShortLineRatio = 1.2;

  #
  # Tabs are replaced with spaces so that the tab stop is at every
  # $TabStop position.
  #
  $TabStop = 8;

  $CenterToleranceRatio = 5;
  }

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

sub text2html {
  my $ptrText = shift;
  my $options = shift;

  @optarr = split( /\n/ , $options);
  %Option = ();
  for( @optarr ){
    if( /^\s*(\w+)\s*=(.*)$/ ){
      $Option{uc($1)} = $2;
      }else{
      $Option{uc($_)} = 1;
      }
    }

  # convert
  #
  #       & ->  &amp;
  #       < ->  &lt;
  #       > ->  &gt;
  $$ptrText =~ s/\&/&amp\;/g;
  $$ptrText =~ s/\</&lt\;/g;
  $$ptrText =~ s/\>/&gt\;/g;

  # delete empty lines from the start of the document
  #
  # +------------------          +------------------
  # |                            |here is the document...
  # |                         -> |
  # | here is the document...    |
  $$ptrText =~ s/^\n*//;

  # Paragraphs are separated by empty lines. But two or
  # more empty lines are useless. Reduce multiple empty
  # lines to one.
  #
  while( $$ptrText =~ s/\n\n\n/\n\n/g ){}

  @Paragraphs = ();

  # split the text to lines
  @lines = split(/\n/,$$ptrText);

  # convert tabs to spaces
  # the tab stop is at every $TabStop position
  #
  #
  # text TAB----|text    -> text         text
  #                                ^
  #                                |
  #                                +-- spaces here
  #
  for( @lines ){
    while( /(.*?)\t/ ){
      $len = $TabStop - length($1)%$TabStop;
      if( $len == 0 ){ $len = $TabStop; }
      $spcs = ' ' x $len;
      s/(.*?)\t/$1$spcs/;
      }
    #if a line contains only spaces then it is empty -> make it really empty
    if( /^\s*$/ ){ $_ = '' }
    }

  # cut off spaces if all lines are padded with spaces
  #
  # +---------------                  +---------------
  # |  the editor saved the file      |the editor saved the file
  # |  idented with some leading   -> |idented with some leading
  # |  space                          |space
  # +---------------                  +---------------
  #
  $LeadingSpaceNr = 1000;   #this should be large enough

  # first calculate the number of spaces that can be found
  # leading each line
  for( @lines ){
    next if length($_) == 0;# empty lines are just any number of spaces
    /^(\s*)/;               # count the leading spaces
    if( length($1) < $LeadingSpaceNr ){
      $LeadingSpaceNr = length($1);
      last if $LeadingSpaceNr == 0;
      }
    }
  # if there is any leading space on each line then delete them
  if( $LeadingSpaceNr ){
    for( @lines ){
      s/^\s{$LeadingSpaceNr}//;
      }
    }

  # Calculate average line length
  #
  # first calculate the maximal line length:
  #                   how long is the longest line?
  $MaximalLineLength = 0;
  for( @lines ){
    $MaximalLineLength = length($_) if $MaximalLineLength < length($_);
    }

  $AverageLineLength = $MaximalLineLength;
  $SumLineLength = 0;
  $LineNr  = 0;
  for( @lines ){
    if( length($_) * $ShortLineRatio > $MaximalLineLength ){
      $SumLineLength += length($_);
      $LineNr++ if length($_);
      }#else{ forget short lines  }
    }

  die 'Is input file empty?' if $LineNr == 0 ;

  $AverageLineLength = $SumLineLength / $LineNr;
  $CenterTolerance = $AverageLineLength / $CenterToleranceRatio;

  #split into paragraphs. a hrule is a paragraph
  $paragraph = ''; #reset the current paragraph
  $PreviousLineLength = 1000;
  LINE:
  for( @lines ){

    #
    # EMPTY LINE terminates paragraph
    #
    if( length == 0 ){
      chomp $paragraph; # takeoff the last \n that was added
      if( length($paragraph) ){ # if there is a paragraph at all then
        push @Paragraphs,$paragraph; # add it to the list
        }
      $paragraph = ''; # reset the current paragraph variable and
      $PreviousLineLength = 1000;
      next LINE;       # go on for the next paragraph
      }


    #
    #  -------------- (horizontal rule) terminates paragraph
    # 
    $hrule = 0; # this line is not a hrule (yet)
    for $hr (@hrule){ # check each hrule character
      if( /^\s*$hr{4}$hr*\s*$/ ){# if the line is nothing more than spaces and at least four hrule chars
        chomp $paragraph; # takeoff the last \n that was added
        if( length($paragraph) ){# if there is a paragraph at all then
          push @Paragraphs,$paragraph,'<HR>';# add it to the list, and add a hrule
          }else{# if there is no real paragraph built up, 
          push @Paragraphs,'<HR>';# then add just the hrule
          }
        $paragraph = '';# reset the current paragraph variable and
        $PreviousLineLength = 1000;
        next LINE;      # go on for the next paragraph
        }
      }

    #
    #  This type of line break.
    #                             Also starts a new paragraph.
    #
    if( /^(\s+)/ ){
      if( length($1) >= $PreviousLineLength ){
        if( length($paragraph) ){
          push @Paragraphs,$paragraph;
          }
        $paragraph = '';
        #next; #oh, no no: do NOT loose lines
        # just go on and fetch the first line of the paragraph...
        }
      }
    $paragraph .= "$_\n";
    $PreviousLineLength = length;
    }

  #
  # Add the last paragraph to the list
  #
  chomp $paragraph;
  if( $paragraph ){
    push @Paragraphs,$paragraph;
    }


  #
  # Remove the leading horizontal rules.
  #
  while( $Paragraphs[0] =~ /<HR>/ ){ shift @Paragraphs }

  #
  # The first paragraph might be the title
  $Title = $Paragraphs[0];

  if( ($Paragraphs[0] =~ s/\n/\n/sg) < $MaximalNumberOfTitleLines ){
    @TitleLines = split(/\n/,$Paragraphs[0]);

    #
    # Decide if it has to be centered
    #
    $center = 1;
    for( @TitleLines ){
      s/^(\s*)//;
      $NumberOfLeadingSpaces = length($1);
      s/\s*$//;
      $zero = $AverageLineLength - length($_) - 2*$NumberOfLeadingSpaces;
      # center if all lines are centered
      last unless $center = ( $center && $zero > -$CenterTolerance && $zero < $CenterTolerance);
      }
    # rebuild the paragraph with line breaks
    $Paragraphs[0] = join("\n<BR>\n",@TitleLines);
    # make it to be a title
    $Paragraphs[0] = '<H1>' . $Paragraphs[0] . '</H1>';
    if( $center ){# center it if it is centered in the text
      $Paragraphs[0] = '<CENTER>' . $Paragraphs[0] . '</CENTER>';
      }
    $BodyStart = 1; # paragraph index where the body starts
    }else{# there are too many lines in the first paragraph to be title
    $Title = $Paragraphs[0];
    $BodyStart = 0; # paragraph index where the body starts, include the first (index=zero)
    }

  $Title =~ s/\n.*//g;#keep the first line of the title

  #
  # Go on for all the paragraphs
  #
  for $paragraph (@Paragraphs[$BodyStart ... $#Paragraphs] ){
    @lines = split(/\n/,$paragraph);# get the lines of the paragraph
    $linr = $#lines+1;
  
    #
    # Try to decide if this paragraph is going to be verbatim
    #
    $p = $paragraph; # copy the paragraph for the check

    #
    # special characters are _ / \ # @ { } [ ] & < >
    #
   # *SpecialCharacter = \'[\_\/\\\#\@\{\}\[\]\|]|\&amp\;|\&lt\;|\&gt\;';
     *SpecialCharacter = \'[\|\_\/\\\#\@\{\}\[\]\|]|\&amp\;|\&lt\;|\&gt\;';
    $SpecialCharacterCounter1 = $p =~ s/$SpecialCharacter//g; # spec chars in the paragraph
    $SpecialCharacterCounter2 = 0;                            # how many lines contain spec chars
    $SpecialCharacterCounter3 = 0;                            # how many lines start with spec char
    $NormalCharacterCounter1 = $p =~ s/\w//g;
    for( @lines ){
      $SpecialCharacterCounter2 ++ if /$SpecialCharacter/;
      $SpecialCharacterCounter3 ++ if /^($SpecialCharacter)/;
      }

    # this is rather heuristic
    if( $SpecialCharacterCounter1*4 >= $NormalCharacterCounter1 ||
        ($SpecialCharacterCounter2 == $linr &&
               $SpecialCharacterCounter1*3 >= $NormalCharacterCounter1)||
        ($SpecialCharacterCounter3 * 2 >= $linr && $linr > 2)
      ){
      if( $Option{PRESTART} ){
        $paragraph = $Option{PRESTART} . "\n" . $paragraph;
        }else{
        $paragraph = "<PRE>\n" . $paragraph;
        }
      if( $Option{PREEND} ){
        #$paragraph .= "\n" . $Option{PREEND} . "\n" ;
        $paragraph .= "" . $Option{PREEND} . "\n" ;
        }else{
        #$paragraph .= "\n</PRE>\n";
        $paragraph .= "</PRE>\n";
        }
      next;
      }

    #
    # Try to decide if this paragraph is going to be BLOCKQUOTE
    #
    if( $linr > 1 && $lines[0] =~ /^(\s*)/ ){
      $StartSpaceNumber = length($1);
      $lines[1] =~ /^(\s*)/;
      $ContinueSpaceNumber = length($1);
      $bq = $ContinueSpaceNumber;
      for( @lines[2 .. $#lines] ){
        /^(\s*)/;
        if( $ContinueSpaceNumber != length($1) ){
          $bq = 0;
          last;
          }
        }
      if( $bq ){
        if( $StartSpaceNumber >= $ContinueSpaceNumber ){
        # This is like
        #
        #      xxxx xx x x xxxx x x
        #   xxx xx x x x xxxx x x
        #   xx x x x xx x x x x x x
        #   x x  x x x x x x xx x x
          $paragraph = "<BLOCKQUOTE>\n" . $paragraph . "\n</BLOCKQUOTE>\n";
          }else{
        # This is like
        #
        # xxxx xx
        #   xxx xx x x x xxxx x x
        #   xx x x x xx x x x x x x
        #   x x  x x x x x x xx x x
          $lines[0] =~ /^\s*(\S+)\s*/;
          $bltl=length($1);
          $lines[0] =~ /^(\s*\S+\s*)/;
          if( $ContinueSpaceNumber == length($1) && $bltl > 1){
            $paragraph =~ s/^\s*(\S+)\s*/<DL>\n<DT>$1<DD>/;
            $paragraph .= '</DL>';
            # as we have modified the paragraph in the variable $paragraph and
            # we still going to make further processing the array @lines
            # now containing the lines of the paragraph should be rebuilt
            @lines = split(/\n/,$paragraph);
            }
          }
        }
      }

  #  
  # Check bulleted list
  #
    %bullet = ();
    for( @lines ){
      if( /^\s*(\S)\s+/ ){# like:   o here it is, or * this is a bulleted line
        my $blt = $1; # fetch the bullet character
        if( $blt =~ /$nobullet_regexp/ ){ next } # if this character is excluded, can not be a bullet
        if( $bullet{$blt} ){ $bullet{$blt}++ }   # count this bullet
        else { $bullet{$blt} = 1 }               # if this is the first occurence of this bullet
        }
      }
    $max = 0; $bullet = undef;
    # now bullets compete, which appears the most in the front of the lines
    while( ($b,$v) = each %bullet ){
      if( $v > $max ){
        $bullet = $b;
        $max = $v;
        }
      }
    if( $max > 1 ) { # we need at least two bulleted lines ...
      $bullet = quotemeta $bullet;
      $start_it = 1;
      for( @lines ){
        if( s/^\s*$bullet\s+// ){
          if( $start_it ){
            $_ = "<UL>\n<LI>" . $_;
            $start_it = 0;
            }else{
            $_ = '<LI>' . $_;
            }
          }
        }
      $paragraph =  join("\n",@lines) . "\n</UL>\n";
      next;
      }

  #  
  # Check numbered list
  #
    $number = 1;
    for( @lines ){
      if( /^\s*(\d+)\.?\s+/ ){
        if( $1 == $number ){
          $number++;
          }
        }
      }
 
    if( $number > 2 ){# we need at least three numbered items
      $number = 1;
      for( @lines ){
        if( /^\s*(\d+)\.?\s+/ ){
          if( $1 == $number ){
            s/^\s*(\d+)\.?\s+/<LI>/;
            if( $number == 1 ){
              $_ = "<OL>\n" . $_;
              }
            $number++;
            }
          }
        }
      $paragraph =  join("\n",@lines) . "\n</OL>\n";
      next;
      }


  #  
  # Check centered paragraph
  #
    if( $linr < 6 ){
      $center = 1;
      @hlines = @lines;
      $hlines[0] =~ /^(\s*)/;
      $fpnr = length($1);
      $olle = 1;
      for( @hlines ){
        s/^(\s*)//;
        $spnr = length($1);
        $olle = $olle && ($spnr == $fpnr);
        s/\s*$//;
        $zero = $AverageLineLength - length($_) - 2*$spnr;
        $center = ( $center && $zero > -$CenterTolerance &&
                    $zero < $CenterTolerance && $spnr > 0);
        }
      if( $linr >2 && $center && $olle ){ $center = 0 }
      if( $center ){
        #joining centered lines w/o breaking might loose meaningful formatting
        $paragraph = '<CENTER>' . join("<BR>\n",@hlines) . '</CENTER>';
        @lines = split(/\n/,$paragraph);
        }
      }
  
  # check paragraph that should be broken to lines
    $max = 0;
    $allcap = 1;
    for( @lines ){
      $max = length($_) if length($_) > $max;
      $capnr = s/([A-Z])/$1/g;
      $ncapr = s/([^A-Z])/$1/g;
      $allcap = $allcap && ($capnr > $ncapr);
      }
    if( $allcap || 2*$max < $AverageLineLength ){
      $paragraph =join("\n<BR>\n",@lines);
      next;
      }
    }
  
  # check bulleted paragraphs
  $bulletStart = -1;
  for $i ($BodyStart ... $#Paragraphs ){
    $j = ($Paragraphs[$i] =~ /^\s*(\S)\s+/);
    $blt = $1;
    if( $j && $blt !~ /$nobullet_regexp/ ){
      if( $bulletStart == -1 ){
        $bulletStart = $i;
        $bullet = $blt;
        next;
        }
      if( $bullet eq $blt ){
        next;
        }
      $bullet = $blt;
      if( $i-1 > $bulletStart || $bullet =~ /$bullet_regexp/ ){
        for $j ($bulletStart ... $i-1){
          $Paragraphs[$j] =~ s/^\s*(\S)\s+/\<LI\>/;
          }
        $Paragraphs[$bulletStart] = "<UL>\n" . $Paragraphs[$bulletStart];
        $Paragraphs[$i-1] .= "\n</UL>";
        }
      $bulletStart = $i;
      } else {
      if( $bulletStart > -1 && ($i-1 > $bulletStart || $bullet =~ /$bullet_regexp/) ){
        for $j ($bulletStart ... $i-1){
          $Paragraphs[$j] =~ s/^\s*(\S)\s+/\<LI\>/;
          }
        $Paragraphs[$bulletStart] = "<UL>\n" . $Paragraphs[$bulletStart];
        $Paragraphs[$i-1] .= "\n</UL>";
        }
      $bulletStart = -1;
      }
    }
  
  # check numbered paragraphs
  $numberStart = -1;
  $number = 1;
  for $i ($BodyStart ... $#Paragraphs ){
    $j = ($Paragraphs[$i] =~ /^\s*(\d+)\.?\s+/);
    $num = $1;
    if( $j ){
      if( $numberStart == -1 && $num == 1){
        $numberStart = $i;
        $number++;
        next;
        }
      if( $num == $number++ ){
        next;
        }
      if( $numberStart > -1 && $i-1 > $numberStart ){
        for $j ($numberStart ... $i-1){
          $Paragraphs[$j] =~ s/^\s*(\S)\.?\s+/\<LI\>/;
          }
        $Paragraphs[$numberStart] = "<OL>\n" . $Paragraphs[$numberStart];
        $Paragraphs[$i-1] .= "\n</OL>";
        }
      if( $num == 1 ){
        $numberStart = $i;
        $number = 2;
        }else{
        $numberStart = -1;
        $number = 1;
        }
      }else{
      if( $numberStart > -1 && $i-1 > $numberStart ){
        for $j ($numberStart ... $i-1){
          $Paragraphs[$j] =~ s/^\s*(\S)\.?\s+/\<LI\>/;
          }
        $Paragraphs[$numberStart] = "<OL>\n" . $Paragraphs[$numberStart];
        $Paragraphs[$i-1] .= "\n</OL>";
        }
      $numberStart = -1;
      $number = 1;
      }
    }
  
  # check headlines, create toc
  @toc = ();
  for $paragraph (@Paragraphs[$BodyStart ... $#Paragraphs] ){
    @lines = split(/\n/,$paragraph);
  if( $#lines == 0 ){
    $_ = $lines[0];
    if( /^\s*\d+\.?\s+/ ||
        /^\s*\d+\.\d+\.?\s+/ ||
        /^\s*\d+\.\d+\.\d+\.?\s+/ ||
        /^\s*\d+\.\d+\.\d+\.\d+\.?\s+/ ||
        /$allcapsheader/ || #a line full caps
        0
        ){
      push @toc,$paragraph;
      next;
      }
    }
  }

if( $#toc > 2 ){
  $tocerror = 0;
  @h = (0,0,0,0);
  for( @toc ){
    if( /$allcapsheader/ ){ next }
    if( /^\s*(\d+)\.?\s+/ ){
      @h[1..3] = (0,0,0);
      if( $1 != ++$h[0] ){
        $h[0] = $1;
        $tocerror++;
        }
      next;
      }
    if( /^\s*(\d+)\.(\d+)\.?\s+/ ){
      @h[2..3] = (0,0);
      if( $1 != $h[0] || $2 != ++$h[1] ){
        $h[0] = $1;
        $h[1] = $2;
        $tocerror++;
        }
      next;
      }
    if( /^\s*(\d+)\.(\d+)\.(\d+)\.?\s+/ ){
      @h[3] = 0;
      if( $1 != $h[0] || $2 != $h[1] || $3 != ++$h[2] ){
        $h[0] = $1;
        $h[1] = $2;
        $h[2] = $3;
        $tocerror++;
        }
      next;
      }
    if( /^\s*(\d+)\.(\d+)\.(\d+)\.(\d+)\.?\s+/ ){
      if( $1 != $h[0] || $2 != $h[1] || $3 != ++$h[2] ){
        $h[0] = $1;
        $h[1] = $2;
        $h[2] = $3;
        $h[3] = $4;
        $tocerror++;
        }
      next;
      }
    }

  %tocc = ();
  for $toce (@toc){
    $tocc{$toce} = 0;
    }

  # emphasize headlines
  $tocnr = 0;
  for $paragraph (@Paragraphs[$BodyStart ... $#Paragraphs] ){
    @lines = split(/\n/,$paragraph);
    if( $#lines == 0 ){
      $_ = $lines[0];
      if( /$allcapsheader/ ){
#        $paragraph = "<B><A NAME=\"toc$tocnr\">" . $paragraph . '</A></B>';
        $paragraph = "<h3><A NAME=\"toc$tocnr\">" . $paragraph . '</A></h3>';
        $tocnr++;
        next;
        }
      if( /^\s*\d+\.?\s+/ ){
        $paragraph = "<H2><A NAME=\"toc$tocnr\">" . $paragraph . '</A></H2>';
        $tocnr++;
        next;
        }
      if( /^\s*\d+\.\d+\.?\s+/ ){
        $paragraph = "<H3><A NAME=\"toc$tocnr\">" . $paragraph . '</A></H3>';
        $tocnr++;
        next;
        }
      if( /^\s*\d+\.\d+\.\d+\.?\s+/ ){
        $paragraph = "<H4><A NAME=\"toc$tocnr\">" . $paragraph . '</A></H4>';
        $tocnr++;
        next;
        }
      if( /^\s*\d+\.\d+\.\d+\.\d+\.?\s+/ ){
        $paragraph = "<H5><A NAME=\"toc$tocnr\">" . $paragraph . '</A></H5>';
        $tocnr++;
        next;
        }
      }
	# Make internal TOC links
    for( @lines ){
      $tocnrr = 0;
      for $toce (@toc){
        #$tocc{$toce} += s/($toce)/\<A\ HREF\=\"\#toc$tocnr\"\>$1\<\/A\>/ig;
        $tocnrr++;
        }
      }
    $paragraph = join("\n",@lines);
    }
  }

#create toc
if( $tocerror *2 < $#toc && $#toc > 3 ){
  $tocnr = 0;
  @tocr = @toc;
  for( @tocr ){
    $_ = "<LI><A HREF=\"\#toc$tocnr\">$_</A>";
    $tocnr++;
    }
  $toc = "<HR>\n<UL>" . join("\n",@tocr) . "</UL>\n<HR>";
  }else{
#there are too many errors, probably this is not a toc
  $toc = '';
  }

for( @toc ){
  s/^\s*(\d+\.)*\d+\s*//;
  $_ = quotemeta lc $_;
  }

  #decide whether there is already a TOC
  $mktoc = 0;
  while( ($toce,$count) = each %tocc ){
    if( $count == 0 ){
      $mktoc = 1;
      last;
      }
    }
  $toc = '' unless $mktoc;

  $$ptrText = "<HTML>\n<HEAD>\n<TITLE>$Title</TITLE>\n<HEAD>\n" unless $Option{'NOHEAD'};
  $$ptrText .= "<BODY bgcolor=\"#ffffff\">\n" unless $Option{'NOHEAD'};
  $$ptrText .= '<FONT '                            if $Option{'FONTFACE'} || $Option{'FONTSIZE'};
  $$ptrText .= 'FACE=' . $Option{'FONTFACE'} . ' ' if $Option{'FONTFACE'};
  $$ptrText .= 'SIZE=' . $Option{'FONTSIZE'}       if $Option{'FONTSIZE'};
  $$ptrText .= ">\n"                               if $Option{'FONTFACE'} || $Option{'FONTSIZE'};
  $$ptrText .= $Paragraphs[0] . "\n<P>" if $BodyStart > 0;
  $$ptrText .= $toc unless $Option{'NOTOC'};
  $$ptrText .= join("\n\n<P>",@Paragraphs[1 .. $#Paragraphs]);
  $$ptrText .= "\n</FONT>"                           if $Option{'FONTFACE'} || $Option{'FONTSIZE'};
  $$ptrText .= "\n</BODY>\n</HTML>\n" unless $Option{'NOHEAD'};

  #you better never try to understand
  $$ptrText =~ s/\<P\>\n\<HR\>/\n\<HR\>/g;
  $$ptrText =~ s/\<HR\>\n\<P\>/\<HR\>\n/g;
  $$ptrText =~ s/\<HR\>\n?\<HR\>/\<HR\>\n/g;
  $ttStart = '<tt>';
  $ttStart = $Option{'TTSTART'} if defined $Option{'TTSTART'};
  $ttEnd   = '</tt>';
  $ttEnd   = $Option{'TTEND'} if defined $Option{'TTEND'};

  #$$ptrText =~ s/\b([\w\.\d\_\-]+\@[\w\.\d\_\-]+)\b/${ttStart}<A HREF=\"mailto:$1\"\>$1<\/A\>${ttEnd}/g;
  # Require that 'mailto' be prefaced with a space.
  $$ptrText =~ s/\s\b([\w\.\d\_\-]+\@[\w\.\d\_\-]+)\b/${ttStart} <A HREF=\"mailto:$1\"\>$1<\/A\>${ttEnd}/g;
  #$$ptrText =~ s#((?:http|ftp|news|gopher)://[\w\d\.-_]+)\b#${ttStart}<A HREF=\"$1\">$1</A>${ttEnd}#g;
  # Also allow "#" and "-"
  $$ptrText =~ s#((?:http|ftp|news|gopher)://[\w\d\.-_\-\#]+)\b#${ttStart}<A HREF=\"$1\">$1</A>${ttEnd}#g;
  $$ptrText =~ s/(copyright)\s*\(c\)/$1\ &#169;/gi;
  $$ptrText =~ s/\(c\)\s*(copyright)/&#169;\ $1/gi;
  $$ptrText =~ s/\(C\)/$1\ &#169;/g;
  $$ptrText =~ s/\(R\)/&#174;/g;
  $$ptrText =~ s/\[TM\]/&#153;/g;
  return $ptrText;
  }

1;