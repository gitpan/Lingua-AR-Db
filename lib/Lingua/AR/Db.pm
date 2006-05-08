package Lingua::AR::Db;

use strict;
use warnings;
use utf8;
use Switch;
use Carp;
use MLDBM qw(DB_File Storable);
use Fcntl;
use Lingua::AR::Word;


our $VERSION = '2.10';


sub new{

    my $class=shift;

    my %db;
    tie %db,'MLDBM',$_[0],O_CREAT|O_RDWR,0640 or croak "Can't open/create the DB: $!";
    (tied %db)->DumpMeth('portable');    # Ask for portable binary

    my $this=\%db;
    bless($this,$class);
}


sub value{	# appends a new translation to the arabic word

    my ($this,$arabic_word,@new_values)=@_;

    my $obj=Lingua::AR::Word->new($arabic_word);

    my $stem=Lingua::AR::Word::encode($obj->get_stem());
    my $word=Lingua::AR::Word::encode($obj->get_word());

    my $ref=$this->{$stem};
	my $ref_translations;

	if(defined($ref->{$word})){
		$ref_translations=$ref->{$word};
	}
	else{
		my @translations;
		$ref_translations=\@translations;
	}

	push @{$ref_translations},@new_values;

	$ref->{$word}=$ref_translations;
    $this->{$stem}=$ref;

}


sub delete{	# deletes a translation array by deleting a word

    my ($this,$arabic_word,@new_values)=@_;

    my $obj=Lingua::AR::Word->new($arabic_word);

    my $stem=Lingua::AR::Word::encode($obj->get_stem());
    my $word=Lingua::AR::Word::encode($obj->get_word());

    my $ref=$this->{$stem};
	my $ref_translations;

	if(defined($ref->{$word})){
		$ref->{$word}=undef;
	}

    $this->{$stem}=$ref;

}



sub translate{	# returns the sorted array of the translations

    my ($this,$arabic_word)=@_;

    my $obj=Lingua::AR::Word->new($arabic_word);

    my $stem=Lingua::AR::Word::encode($obj->get_stem());
    my $word=Lingua::AR::Word::encode($obj->get_word());

	if(defined(@{$this->{$stem}{$word}})){
    	return sort @{$this->{$stem}{$word}};
	}
	else{
		return undef;
	}
}


sub export{ # exports the dictionary in text format

    my $this=shift;
    my $output_string;

    my @stems=sort keys(%{$this});

    foreach my $stem (@stems){
        if($stem=~/\w+/){
            my @words=keys(%{$this->{$stem}});
            foreach my $word (@words){
                if(defined(@{$this->{$stem}{$word}})){
                    foreach (sort @{$this->{$stem}{$word}}){
                        $output_string.=$stem."::$word\t$_\n";
                    }
                }
            }
        }
    }

    return $output_string;
}


sub export_html{ # exports the dictionary in html form

    my $this=shift;
    my $dir=shift;


	if(!defined($dir)){
		croak "Please specify the HTML folder to export the database to\n";
	}
    if(!-e $dir){
        mkdir $dir, 0755 or croak "Can't create the directory $dir: $!\n";
    }
    open INDEX, ">:utf8","$dir/index.html" or croak "Cannot create $dir/index.html: $!\n";
    print INDEX &html_header("Dictionary","Index");

    my @stems=sort keys(%{$this});

    print INDEX "<ol>\n";


    foreach my $stem (@stems){

        if($stem=~/\w+/){   #needed check as there's one undef key

            my @words=sort keys(%{$this->{$stem}});
            print INDEX "\t<li><a href=\"./stem-$stem.html\">$stem</a></li>\n";
            open STEM, ">:utf8","$dir/stem-$stem.html" or croak "Cannot create $dir/stem-$stem.html: $!\n";

            print STEM &html_header("Stem: $stem","Stem: $stem");
            print STEM "<small>back to the <a href=\"./index.html\">index page</a></small>\n\n<ol>\n";

            foreach my $word (sort @words){
                print STEM "\t<li>$word: \n";

				print STEM "\t\t<ul>\n";
				foreach(@{$this->{$stem}{$word}}){
					print STEM "\t\t<li>$_</li>\n";
				}

				print STEM "\t\t</ul>\n</li>\n";
            }
            print STEM "</ol>\n</div>\n</body>\n</html>";
            close STEM;
        }
    }
    print INDEX "</ol>\n";


    print INDEX "</div>\n</body>\n</html>";
    close INDEX;
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

</head>
<body><div id=\"body\"><h1>$_[1]</h1>\n";

return $header;
}




1;
__END__

=head1 NAME

Lingua::AR::Db - Perl extension for translating Arabic words into another language

=head1 SYNOPSIS

	use utf8;
	use Lingua::AR::Db;

	# this will create a new DB or load an already existent DB
	my $db=Lingua::AR::Db->new($db_name);


	# this will append new translations to the word "مكتب"
	my $arabic_word="مكتب";
	$db->value($arabic_word,@translations);

	# let's print out all the translations of the $arabic_word
	my @array=@{$db->translate($arabic_word)};
	foreach(@array){
		print "$arabic_word means $_\n";
	}

	# this will return every entry of the Database,
	# formatted as "STEM::WORD\tTRANSLATION"
	my $dump=$db->export;
	print $dump;

	# this will export the Database in HTML form under the "./html/" directory
	$db->export_html("./html");




=head1 DESCRIPTION

This module will take care of the translating an Arabic word into another language through a persistent hash located in a Database.

You may add new values (translations) to the DB, as well as getting the translation back and exporting into text format or HTML the whole DB.

The DB is structured as a double hash: primary key is the stem of the word, the second key is the word itself.
The resulting value pointed by these two keys is the translations array.


If you're interested in a front-end to this module, I'm going to develop one based on Qt widgets.
More info @ www.qitty.net

I'm going to publish my own Arabic->Italian dictionary on my site @ www.qitty.net

=head1 NOTE

Please note that every time you inquire the DB, your arabic word and/or the stem of it, is encoded into ArabTeX.
This is because Unicode strings can't be keys of the hash at any level.


=head1 SEE ALSO

On my site, you may get additional info about this module.
You may find more info about ArabTeX at ftp://ftp.informatik.uni-stuttgart.de/pub/arabtex/arabtex.htm


=head1 TODO

=over

=item correct use of delete and consequent export[_html]

=item display Arabic characters (instead of|along with) the translitterated ones and sort them according to the Arabic alphabet

=item add accessory methods and variables as needed (translation language,..)

=item export to XML

=back


=head1 AUTHOR

Andrea Benazzo, E<lt>andy@slacky.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Andrea Benazzo. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.


=cut
