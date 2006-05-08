# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-AR-Db.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
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

# let's test correct sorted translations
$db->value($arabic_word,"library","book shop");
is(($db->translate($arabic_word))[0],"book shop","translation: first value");
is(($db->translate($arabic_word))[1],"library","translation: second value");

# let's test correct sorted dump values
is($db->export,"ktb::mktb\tbook shop\nktb::mktb\tlibrary\n","exportation");

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
like($data,qr{mktb},"html exportation: stem");
like($data,qr{library},"html exportation: stem");
like($data,qr{book shop},"html exportation: stem");
close STEM;

# let's test the correctness of the delete method
$db->delete($arabic_word);
is(($db->translate($arabic_word))[0],undef,"delete: first value");
is(($db->translate($arabic_word))[1],undef,"delete: second value");



# let's clean the test environment
unlink <$html_folder/*.html>;
rmdir $html_folder;
unlink $database_name;