package Lingua::AR::Db;

use 5.008006;
use strict;
use warnings;
use utf8;


use Switch;


our @ISA = qw();

our $VERSION = '1.51';


sub new{

	my $this={
		FOLDER=>$_[1],
		LANG=>$_[2]
	};

	if(!-e $this->{FOLDER}){
		warn "$this->{FOLDER} doesn't exists..creating it";
		mkdir $this->{FOLDER}, 0755 or die "Can't create the $this->{FOLDER} directory: $!\n";
	}

	bless($this);

return $this;
}



sub translate{

	my $db=shift;
	my $word=shift;
	my $translation="TRANSLATION: NotFound\n\n";

	my $input=Lingua::AR::Word::encode($word->{STEM});
	$input=($db->{FOLDER})."/%".$input;

	if (-e $input){
		open DICT, "<".$input or die "Error in opening $input: $!";
		binmode(DICT,":utf8");
		#look for the translation
		my $found=0;
		while($found==0 and my $line=<DICT>){
			chomp($line);
			if($line=~/^($word->{WORD})/){
				$translation="TRANSLATION: $'\n\n";
				$found=1;
			}
		}
		if(!$found){
			$translation="No translation found\n\n";
		}
	}
	else{
		warn "Cannot find the file $input: $!\n";
	}

return $translation;
}


sub display_html{ # exports the dictionary in html form

	my $this=shift;

	if(!-e "html"){
		mkdir "html", 0755 or die "Can't create the html directory: $!\n";
	}
	open INDEX, ">./html/index.html" or die "Cannot create ./html/index.html: $!\n";
	binmode(INDEX,":utf8");
	print INDEX &html_header("Dictionary");
	print INDEX
"<div id=\"body\"><body>
<h1>Available stems</h1>\n";

	my @alphabet=("ا","ب","ت","ث","خ","ح","ج","د","ذ","ر","ز","س","ش","ص","ض","ط","ظ","ع","غ","ف","ق","ك","ل","م","ن","ه","و","ي","NotFound");
	foreach my $letter (@alphabet){
	print INDEX "<h2>$letter</h2>\n<ol>\n";
	$letter=Lingua::AR::Word::encode($letter);
	my @dicts=glob($this->{FOLDER}."/%$letter*");
	
print "Letter: $letter\n";
print "dictionaries: @dicts\n";

	foreach my $file (@dicts){
		my $filename=substr($file,8);
		open FOUTPUT, ">./html/$filename.html" or die "Cannot create ./html/$filename.html: $!\n";
		binmode(FOUTPUT,":utf8");

		open FINPUT, "<".$file or die "Cannot open $file: $!\n";
		binmode(FINPUT,":utf8");
		
		#get the stem name
		chomp(my $line=<FINPUT>);
		$line=~s/^\t//;

		print INDEX "<li><h3><a href=\"./$filename.html\">$line</a></h3></li>\n";
		print FOUTPUT &html_header($line);
		print FOUTPUT
"<body>
<div id=\"body\">
<a href=\"./index.html\">Stem index</a>
<center><h1>$line</h1></center>
<ol>\n";
		#eats the newline
		$line=<FINPUT>;
		#gets the translations
		while($line=<FINPUT>){
			chomp($line);
			$line=~/(.*)\t/;
			print FOUTPUT "<li><h4>$1 $'</h4></li>";
		}
	print FOUTPUT "</div></ol></body></html>";
	close FOUTPUT;
	}
	
	print INDEX "</ol>\n"
}
	print INDEX "</div></body>\n</html>";

	print "\tHTML pages are located in ./html/\n";
}


sub html_header{

	my $header=
"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
<html>
<head>
	<title>$_[0]</title>
	<meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\">
	<style type=\"text/css\">
#body :link, #body :visited {text-decoration: none;}
#body :link:hover, #body :visited:hover {color: #5795ff;}
	</style>

</head>\n";

return $header;
}


sub display_latex{ # creates the LaTeX source file for the whole dictionary

	if(!-e "latex"){
		mkdir "latex", 0755 or die "Can't create the LaTeX directory: $!\n";
	}
	open FOUTPUT, ">./latex/index.tex" or die "Cannot create ./latex/index.tex: $!\n";
	binmode(FOUTPUT,":utf8");
	print FOUTPUT
'\documentclass[a4paper,twoside,openright,titlepage]{report}
\usepackage{arabtex,atrans,nashbf}
\usepackage[italian]{babel}
\usepackage[left=3.5cm, right=3cm, top=4cm, bottom=4cm]{geometry}
\usepackage{makeidx}
\usepackage{float}
\usepackage{inputenc}
\usepackage{utf8}
\setlength{\headsep}{2cm}
\stepcounter{chapter}
\frenchspacing
\setarab
\setnash
\makeindex


\title{\textbf{Arabic-Italian Dictionary}}

\begin{document}
\let \MakeUppercase \relax
\setcode{utf8}\transfalse\arabtrue
\maketitle
';
	my @dicts=glob "./dicts/*";
	foreach my $file (@dicts){
		open FINPUT, "<".$file or die "Cannot open $file: $!\n";
		binmode(FINPUT,":utf8");

		#get the stem name
		chomp(my $line=<FINPUT>);
		$line=~s/^\t//;
		print FOUTPUT "\\section{\\RL{$line} = $}\n";

		#eats the newline
		$line=<FINPUT>;
		#gets the translations
		while($line=<FINPUT>){
			chomp($line);
			if($line=~/^(.*)\t/){
				print FOUTPUT "\\RL{$1} $'\\\\\n";
			}
		}
	}

	print FOUTPUT "\\end{document}";
	close FOUTPUT;

	print "\tLaTeX source file is in ./latex/\n";
}


sub importation{

	my $file;
	my $transl;
	my $word;
	my $count_files=$#_;
	my $count_new_words=0;
	my $count_old_words=0;
	my $count_new_dicts=0;

shift @_; #trashes "import"


foreach $file (@_){
	open FINPUT, "<".$file or die "Cannot open $file: $!\n";
	binmode(FINPUT,":utf8");

	while(my $line=<FINPUT>){
		chomp($line);
		if($line=~/^([\w-]+) = ([\w-]+)/){
			$transl=$1;
			$line=$2;
			$word=$2.$';

			my $stem=&stem($line);
			my $input=&encode($stem);
			$input="%".$input;
			chomp($input="./dicts/".$input);

			if (-e $input){
				open DICT, "+<".$input or die "Error in opening $input: $!\n";
				binmode(DICT,":utf8");
				#look for the translation
				my $found=0;
				while($found==0 and my $read_line=<DICT>){
					chomp($read_line);
					if($read_line=~/^$word\t$transl/){
						$found=1;
						$count_old_words++;
					}
				}
				if(!$found){
					print DICT "$word\t$transl\n";
					$count_new_words++;
				}
			}
			else{
				#create the new stem file
				open DICT, ">".$input or die "Error in creating $input: $!\n";
				binmode(DICT,":utf8");
	
				print DICT "\t$stem\n\n";
				print DICT "$word\t$transl\n";
				$count_new_dicts++;
				$count_new_words++;
			}
			close DICT;
		}
	}
	close FINPUT;
	print "Imported file: $file\n";
}

my @dicts=glob "./dicts/*";

print "Importation completed:
\tfiles processed: $count_files
\tnew words added: $count_new_words
\twords already present: $count_old_words
\tnew stems created: $count_new_dicts
\tstems now available: ".($#dicts+1)."\n";

}


1;
__END__

=head1 NAME

Lingua::AR::Db - Perl extension for translating Arabic words into another language

=head1 SYNOPSIS

  use utf8;
  use Lingua::AR::Word;
  use Lingua::AR::Db;

my $word=Lingua::AR::Word->new(ARABIC_WORD_IN_UTF8);
my $db=Lingua::AR::Db->new(DICT_FOLDER,LANGUAGE);


open FOUTPUT, ">>TEST" or die "Cannot create TEST: $!\n";
binmode(FOUTPUT,":utf8");
print FOUTPUT $db->translate($word);
close FOUTPUT;


$db->display_html();
$db->display_latex();
$db->importation(FILE);

=head1 DESCRIPTION

This module will take care of the translation DB.
You just need to create the DB object, specifying the folder and the language.
Translations will be looked for in the files under that folder, according to the "%".$stem_of_the_word.
This is necessary because the shell will treat as hidden all the files beginning with a dot, whilch may be a beginning ArabTex character.

This module may also export in HTML or ArabTeX all the files, as well as import from other DBs.


=head1 SEE ALSO

You may find more info about ArabTeX at ftp://ftp.informatik.uni-stuttgart.de/pub/arabtex/arabtex.htm



=head1 AUTHOR

Andrea Benazzo, E<lt>andy@slacky.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Andrea Benazzo. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.


=cut
