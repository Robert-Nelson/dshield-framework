#!/usr/bin/perl

#
#  This script will package all the DShield framework clients.  
#  To be run after build_clients.pl
#  It finds all the *.parser files and builds tarballs based on 
#  their existance.
#
#  It also creates the Framework Development Kit.
#

opendir (DIR,".") || die ("can't open dir\n");

# Define how much to read in a single operation.  undef == the whole file.
undef $/;

# Load the existing README.txt file in memory.
open (FILE,"README.txt");
$readme=<FILE>;
close FILE;

# To collect all the headings from the beginning of all the parsers
# This will be written at the end of DEVELOPER.txt
$allheads = "\n\n";
$allheads .= "DOCUMENTATION FOR ALL PARSERS\n\n";

my @files;

foreach ( readdir(DIR) ) {
    # Get *.parser files only
	if ( /(\S+)\.parser$/ ) {

		# All we really want is the base name of the parser file
		$version=$1;
		chomp($version);
		push (@files, $version);
	}
}

my @sfiles = sort @files;

foreach $version (@sfiles) {

	open(FILE,"$version.parser");
    	$file=<FILE>;
	    close FILE;

		# Pick off the beginning of the parser before the first \n\n
		# Assumed to be the introdction comments
		$file =~ /\n\n/s;

		# $head will be appended to the end of the individual README.txt files
		# $' is a Perl variable that contains the string *before* the last
		# match.  In this case, the portion before the first \n\n.
		$head = $`;
		
		# $allheads will be appended to the end of framework/DEVELOPER.txt
		$allheads .= "#-------$version.parser------\n" . $head . "\n\n"; 
		$VERSION = uc $version;
		$head = "\n\nNOTES ON CONFIGURING THE $VERSION FIREWALL\n\n" . $head . "\n";;

		# Create a directory using the base name of the parser
		`/bin/mkdir  -p $version`;
		`/bin/rm -f $version/*`;		
		
		# Now copy all the files that are needed for this client
		# Script is assumed to use the base name
		`/bin/cp -fp ./$version.pl $version`;
		`/bin/cp -fp ./*.lst $version`;
		`/bin/cp -fp ./dshield.cnf $version`;
		`/bin/cp -fp ./test.cnf $version`;
		`/bin/cp -fp ./changelog.txt $version`;
		if ( $version eq "linksys" ) {
			`/bin/cp -fp ./linksys.c $version`;
		}		
		if ( $version eq "pfsense" ) {
			`/bin/cp -fp ./pfsense_mailer.php $version`;
			`/bin/cp -fp ./pfsense_preprocessor.php $version`;
		}		

		# Create the sample test_wrapper.sh script
		write_script();

		# Create README.txt that has the heading from the parser
		# appended at the end
		open (FILE, "> $version/README.txt" );
		print FILE $readme;
		print FILE $head;
		close FILE;

		if (chdir("$version")) {
			`/bin/chmod 644 *.txt *.cnf *.lst`;
			`/bin/chmod 755 *.pl`;
			chdir "..";
		} else {
			print "Couldn't change to $version directory\n";
			exit 1;
		}
		
		# basenameed tarball		
		`/bin/tar czf $version.tar.gz $version`;		
		
		print "Created $version.tar.gz\n";
}

$allheads .= "\n\nGLOBAL VARIABLES THAT THE PARSERS SHOULD USE\n\n";
open (FILE,"parserdoc.txt");
$allheads .= <FILE>;
close FILE;

# Now make the framework development kit

`/bin/mkdir -p framework`;
`/bin/rm -f framework/*`;

`/bin/cp -fp framework.pl framework`;
`/bin/cp -fp *.parser framework`;
`/bin/cp -fp *.lst framework`;
`/bin/cp -fp dshield.cnf framework`;
`/bin/cp -fp test.cnf framework`;
`/bin/cp -fp build_clients.pl framework`;
`/bin/cp -fp package_clients.pl framework`;
`/bin/cp -fp README.txt framework`;
`/bin/cp -fp changelog.txt framework`;
`/bin/cp -fp parserdoc.txt framework`;
`/bin/cp -fp text2html.pl text2html.pm framework`;

# Write the accumulated parser headings to the end of DEVELOPER.txt
open (FILE,"DEVELOPER.txt");
$readme=<FILE>;
close FILE;

open (FILE, "> framework/DEVELOPER.txt" );
print FILE $readme;
print FILE $allheads;
close FILE;

if (chdir("framework")) {
	#$s = `pwd`; print "$s\n";
	`/bin/chmod 644 *.txt *.cnf *.lst *.parser`;
	`/bin/chmod 755 *.pl`;
	chdir "..";
	#$s = `pwd`; print "$s\n";
} else {
	print "Couldn't change to framework directory\n";
	exit 1;
}
				
`/bin/tar czf framework.tar.gz framework`;		
		
print "\nCreated framework.tar.gz\n";
                
exit 0;

#-----------End of script----------------------


# Writes the sample wrapper/testing script.
# Stuck it down here to get it out of the way.
sub write_script {

	open (FILE, "> $version/test_wrapper.sh") || die "Can't open $version/test_wrapper.sh\n";
	print FILE <<End_of_stuff;
#!/bin/sh
#
# For testing the DShield framework client
#
# You must change the 'log' variable in test.cnf to point
# to your log file.
#
# Write an arbitrary timestamp to dshield.cnt for testing ONLY.
# Do NOT do this when you are running "for real"
#     YYYYMMDDHHMMSS
echo "20021201000000" > dshield.cnt
#
# Now run the script using test.cnf in the current directory.
# Redirect the verbose debugging output to debug.txt.
End_of_stuff

	print FILE "./$version.pl -config=./test.cnf > debug.txt\n";
	print FILE <<End_of_stuff2;
#
# When you get this working, you can set it up for real operation by
# commenting out the 'echo "20011201000000" > dshield.cnt' line, 
# deleting dshield.cnf, changing the whereto variable in test.cnf to 
# be MAIL, and make sure that the email variables are correct.  Then
# create a crontab entry like
# 
End_of_stuff2

	print FILE "# 10 4 * * * cd {directory}; ./$version.pl -config=./test.cnf > debug.txt\n";
	print FILE "#\n";
	print FILE "# where {directory} is the name of the directory that $version.pl is in.\n"; 
	print FILE <<End_of_stuff3;
#
# See README.txt for more detailed instructions
End_of_stuff3

	close FILE;

	return;
}
