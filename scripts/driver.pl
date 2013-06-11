#!/usr/bin/perl -w
use File::Basename;
use Cwd;
 
$this_dir = getcwd();
#$this_dir = chomp($this_dir);
my $errfile = "errors.txt";
@files = <source_xml/APB19*>;
foreach $file (@files) {

	$cmd_convert = "$this_dir/scripts/xml2tei.pl teip5_xml/ $file\n";
	system($cmd_convert);
	$outfile = basename($file);
	$cmd_check = "xmllint --dtdvalid file:///$this_dir/reference/tei_all.dtd --noout  teip5_xml/$outfile 2> $errfile\n";
	system($cmd_check);
	
	$fileContents = "";
	if (open(FILE, $errfile)) {
	    $fileContents = <FILE>;
	    close FILE;
	    system("rm $errfile");
		print $fileContents;
		if($fileContents ne "") {
			$cmd_recheck = "xmllint --dtdvalid file:///$this_dir/reference/tei_all.dtd teip5_xml/$outfile\n";
			system($cmd_recheck);
			system("gedit source_xml/$outfile teip5_xml/$outfile &\n");
			die "Errors found in $file:\n\nTo reproduce:\n$cmd_convert$cmd_recheck"
			
		}
				
	}
}