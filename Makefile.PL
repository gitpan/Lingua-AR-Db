use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::AR::Db',
    VERSION_FROM      => 'lib/Lingua/AR/Db.pm', # finds $VERSION
    PREREQ_PM         => {'Lingua::AR::Word' => 1.5.4, MLDBM, DB_File},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/AR/Db.pm', # retrieve abstract from module
       AUTHOR         => 'Andrea Benazzo <andy@slacky.it>') : ()),
);
