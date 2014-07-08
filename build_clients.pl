#!/usr/bin/perl

#
#  This script will build the framework clients.
#  It loops throgh all the 'parsers' it can find and creates
#  separate 'parser'.pl files.  'parser'.pl is appended to framework.pl
#  for each client.
#

opendir (DIR,".") || die ("can't open dir\n");

undef $/;

# Load the entire framework.pl file into a variable.
open (FILE,"framework.pl");
$frame=<FILE>;
close FILE;

# Used to "timestamp" when the clients were built.
#$thedate=`date +%d%m%Y`;
$thedate=`date +%Y-%m-%d`;
chop($thedate);

foreach ( readdir(DIR) ) {
  # Get *.parser files only
  if ( /(\S+)\.parser$/ ) {
	print "$1 $_\n";
	$version=$1;
	chomp($version);
	open(FILE,"$version.parser");
	$file=<FILE>;
	close FILE;
	# Pick off the beginning of the parser before the first \n\n
	# Assumed to be the introdction comments
	$file =~ /\n\n/s;
	
	$head=$`;	# Portion of match string before the regex match
	$body=$';	# Portion of match string after the regex match
	# In other words, the portions before and after the first \n\n (blank line)
	# The portion before the first blank line is defined as the header
	# The rest is used as the parser code and is appended to framework.pl

	open(FILE,"> $version.pl");
	print FILE "#!/usr/bin/perl -s \n";

	# We'll work on this later.....
	#print FILE "use strict;\n";
	# The idea would be to keep 'use strict' and eliminate the next three.
	#print FILE 'no strict "vars";' . "\n";
	#print FILE 'no strict "refs";' . "\n";
	#print FILE 'no strict "subs";' . "\n";

	print FILE "\$VERSION='$version\_$thedate\';\n"; 
	print FILE "\$PARSER='";
	print FILE uc($version);
	print FILE "';\n\n";

	# i.e., the intro from this instance of *.parser
	print FILE $head;

	# framework.pl
	print FILE $frame;

	print FILE "\n# End of framework section.\n\n";
	print FILE "\# Beginning of $version Parser\n\n";

	# The rest of this instance of *.parser
	print FILE $body;
	close FILE;
	#`chmod 775 $version.pl`;
  }
}
