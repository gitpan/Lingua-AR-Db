# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-AR-Db.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use utf8;
use strict;
use warnings;

BEGIN {
use utf8;
use_ok('Lingua::AR::Word');
use_ok('Lingua::AR::Db');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $word=Lingua::AR::Word->new("القامع");
ok(defined $word, "Word->new() returned something");
ok($word->isa('Lingua::AR::Word'), "and it's the right class");

my $db=Lingua::AR::Db->new("./dicts","en");
ok(defined $db, "Db->new() returned something");
ok($db->isa('Lingua::AR::Db'), "and it's the right class");

open FOUTPUT, ">./dicts/%qm`" or die "Cannot create ./dicts/%qm`: $!\n";
binmode(FOUTPUT,":utf8");
print FOUTPUT
"\tقمع\n
مقموع	Quelled
القامع	Queller
القمع	Quelling
يقمع	Quells
";
close FOUTPUT;

is($db->translate($word),"TRANSLATION: \tQueller\n\n");

