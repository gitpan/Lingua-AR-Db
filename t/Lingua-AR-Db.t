# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-AR-Db.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use utf8;
use strict;
use warnings;

BEGIN {
use_ok('Lingua::AR::Word');
use_ok('Lingua::AR::Db');
use_ok('MLDBM');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $arabic_word="مكتب";
my $database_name="./database";
my $html_folder="./html";

# let's test correct packet management
my $db=Lingua::AR::Db->new($database_name);
ok(defined $db, "new() returned something");
isa_ok($db,"Lingua::AR::Db");

# let's test correct translation
$db->value($arabic_word,"libreria");
is($db->translate($arabic_word),"libreria","translation");

# let's test correct dump values
is($db->export,"ktb::mktb\tlibreria\n","exportation");

# let's test correct HTML exportation through two cases: check on index page, check on stem page
$db->export_html($html_folder);
my $obj=Lingua::AR::Word->new($arabic_word);
my $stem=Lingua::AR::Word::encode($obj->get_stem);

# check on HTML index page
open INDEX, "<:utf8","./html/index.html" or die "Cannot read ./html/index.html: $!\n";
my @data=<INDEX>;
my $data=join '\n',@data;
like($data,qr{<li><a href="./stem-$stem.html">$stem</a></li>},"html exportation: index");
close INDEX;

# check on HTML stem page
open STEM, "<:utf8","./html/stem-$stem.html" or die "Cannot read ./html/stem-$stem.html: $!\n";
@data=<STEM>;
$data=join '\n',@data;
like($data,qr{<li>mktb = libreria</li>},"html exportation: stem");
close STEM;



# let's clean the test environment
unlink <$html_folder/*.html>;
rmdir $html_folder;
unlink $database_name;