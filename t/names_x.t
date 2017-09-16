# -*- cperl -*-
use strict;
use warnings;
use utf8;
no warnings 'utf8';

use Test::More tests => 20;
use Test::Differences;
unified_diff;

use Biber;
use Biber::Utils;
use Biber::Output::bbl;
use Log::Log4perl;
use Unicode::Normalize;
use Encode;
chdir("t/tdata");

# Set up Biber object
my $biber = Biber->new(noconf => 1);
my $LEVEL = 'ERROR';
my $l4pconf = qq|
    log4perl.category.main                             = $LEVEL, Screen
    log4perl.category.screen                           = $LEVEL, Screen
    log4perl.appender.Screen                           = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.utf8                      = 1
    log4perl.appender.Screen.Threshold                 = $LEVEL
    log4perl.appender.Screen.stderr                    = 0
    log4perl.appender.Screen.layout                    = Log::Log4perl::Layout::SimpleLayout
|;
Log::Log4perl->init(\$l4pconf);

$biber->parse_ctrlfile('names_x.bcf');
$biber->set_output_obj(Biber::Output::bbl->new());

# Options - we could set these in the control file but it's nice to see what we're
# relying on here for tests

# Biber options
Biber::Config->setoption('namesep', 'und'); # Testing custom name splitting string
Biber::Config->setoption('others_string', 'andere'); # Testing custom implied "et al"
Biber::Config->setoption('sortlocale', 'en_GB.UTF-8');
Biber::Config->setblxoption('mincitenames', 3);

# Now generate the information
$biber->prepare;
my $out = $biber->get_output_obj;
my $section = $biber->sections->get_section(0);
my $main = $biber->sortlists->get_list(0, 'nty/global/', 'entry', 'nty', 'global', '');
my $bibentries = $section->bibentries;

my $name1 =
    { given          => {string => 'John', initial => ['J']},
      family         => {string => 'Doe', initial => ['D']},
      basenamestring => 'Doe',
      nameinitstring => 'DoeJ',
      namestring     => 'DoeJohn',
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef}};

my $name2 =
    { given          => {string => 'John', initial => ['J']},
      family         => {string => 'Doe', initial  => ['D']},
      basenamestring => 'Doe',
      nameinitstring => 'DoeJ',
      namestring     => 'DoeJohn',
      prefix         => {string => undef, initial => undef},
      suffix         => {string => 'Jr', initial => ['J']}};

my $name3 =
    { given          => {string => 'Johann~Gottfried', initial => ['J', 'G']},
      family         => {string => 'Berlichingen zu~Hornberg', initial => ['B', 'z', 'H']},
      basenamestring => 'vonBerlichingen zu~Hornberg',
      nameinitstring => 'vonBerlichingen zu~HornbergJG',
      namestring     => 'vonBerlichingen zu~HornbergJohann~Gottfried',
      prefix         => {string => 'von', initial => ['v']},
      suffix         => {string => undef, initial => undef}};

my $name4 =
    { given          => {string => 'Johann~Gottfried', initial => ['J', 'G']},
      family         => {string => 'Berlichingen zu~Hornberg', initial => ['B', 'z', 'H']},
      basenamestring => 'Berlichingen zu~Hornberg',
      nameinitstring => 'Berlichingen zu~HornbergJG',
      namestring     => 'Berlichingen zu~HornbergJohann~Gottfried',
      prefix         => {string => 'von', initial => ['v']},
      suffix         => {string => undef, initial => undef}};

my $name5 =
   {  given          => {string => undef, initial => undef},
      family         => {string => 'Robert and Sons, Inc.', initial => ['R']},
      basenamestring => 'Robert and Sons, Inc.',
      nameinitstring => 'Robert and Sons, Inc.',
      namestring     => 'Robert and Sons, Inc.',
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef}};

my $name6 =
   {  given          => {string => 'ʿAbdallāh', initial => ['A']},
      family         => {string => 'al-Ṣāliḥ', initial => ['Ṣ']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'al-Ṣāliḥ',
      namestring     => 'al-ṢāliḥʿAbdallāh',
      nameinitstring => 'al-ṢāliḥA'} ;

my $name7 =
   {  given          => {string => 'Jean Charles~Gabriel', initial => ['J', 'C', 'G']},
      family         => {string => 'Vallée~Poussin', initial => ['V', 'P']},
      prefix         => {string => 'de~la', initial => ['d', 'l']},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'de~laVallée~Poussin',
      namestring     => 'de~laVallée~PoussinJean Charles~Gabriel',
      nameinitstring => 'de~laVallée~PoussinJCG' } ;

my $name8 =
   {  given          => {string => 'Jean Charles Gabriel', initial => ['J']},
      family         => {string => 'Vallée~Poussin', initial => ['V', 'P']},
      prefix         => {string => 'de~la', initial => ['d', 'l']},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Vallée~Poussin',
      namestring     => 'Vallée~PoussinJean Charles Gabriel',
      nameinitstring => 'Vallée~PoussinJ' } ;

my $name9 =
   {  given          => {string => 'Jean Charles Gabriel de la~Vallée', initial => ['J', 'C', 'G', 'd', 'V']},
      family         => {string => 'Poussin', initial => ['P']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Poussin',
      namestring     => 'PoussinJean Charles Gabriel de la~Vallée',
      nameinitstring => 'PoussinJCGdV'} ;

my $name10 =
   {  given          => {string => 'Jean Charles~Gabriel', initial => ['J', 'C', 'G']},
      family         => {string => 'Vallée Poussin', initial => ['V']},
      prefix         => {string => 'de~la', initial => ['d', 'l']},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Vallée Poussin',
      namestring     => 'Vallée PoussinJean Charles~Gabriel',
      nameinitstring => 'Vallée PoussinJCG' } ;

my $name11 =
   {  given          => {string => 'Jean Charles Gabriel', initial => ['J']},
      family         => {string => 'Vallée Poussin', initial => ['V']},
      prefix         => {string => 'de~la', initial => ['d', 'l']},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Vallée Poussin',
      namestring     => 'Vallée PoussinJean Charles Gabriel',
      nameinitstring => 'Vallée PoussinJ' } ;

my $name12 =
   {  given          => {string => 'Jean Charles~Gabriel', initial => ['J', 'C', 'G']},
      family         => {string => 'Poussin', initial => ['P']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Poussin',
      namestring     => 'PoussinJean Charles~Gabriel',
      nameinitstring => 'PoussinJCG' } ;

my $name13 =
   {  given          => {string => 'Jean~Charles', initial => ['J', 'C']},
      family         => {string => 'Poussin Lecoq', initial => ['P']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Poussin Lecoq',
      namestring     => 'Poussin LecoqJean~Charles',
      nameinitstring => 'Poussin LecoqJC' } ;

my $name14 =
   {  given          => {string => 'J.~C.~G.', initial => ['J', 'C', 'G']},
      family         => {string => 'Vallée~Poussin', initial => ['V', 'P']},
      prefix         => {string => 'de~la', initial => ['d', 'l']},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'de~laVallée~Poussin',
      namestring     => 'de~laVallée~PoussinJ.~C.~G.',
      nameinitstring => 'de~laVallée~PoussinJCG' } ;

# Note that the family initials are wrong because the prefix "El-" was not stripped
# This is because the default noinit regexp only strips lower-case prefices to protect
# hyphenated names
my $name15 =
   {  given          => {string => 'E.~S.', initial => ['E', 'S']},
      family         => {string => 'El-Mallah', initial => ['E-M']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'El-Mallah',
      namestring     => 'El-MallahE.~S.',
      nameinitstring => 'El-MallahES' } ;

my $name16 =
   {  given          => {string => 'E.~S.', initial => ['E', 'S']},
      family         => {string => 'Kent-Boswell', initial => ['K-B']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Kent-Boswell',
      namestring     => 'Kent-BoswellE.~S.',
      nameinitstring => 'Kent-BoswellES' } ;

my $name17 =
   {  given          => {string => 'A.~N.', initial => ['A', 'N']},
      family         => {string => 'Other', initial => ['O']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Other',
      namestring     => 'OtherA.~N.',
      nameinitstring => 'OtherAN' } ;

my $name18 =
   {  given          => {string => undef, initial => undef},
      family         => {string => 'British National Corpus', initial => ['B']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'British National Corpus',
      namestring     => 'British National Corpus',
      nameinitstring => 'British National Corpus' } ;

my $name19 =
   {  given          => {string => 'Bill', initial => ['B']},
      family         => {string => 'Smith', initial => ['S']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Smith',
      namestring     => 'SmithBill',
      nameinitstring => 'SmithB',
      sortnamekeyscheme => 'test' } ;

my $name20 =
   {  given          => {string => undef, initial => undef},
      family         => {string => 'Doe', initial => ['Do']},
      prefix         => {string => undef, initial => undef},
      suffix         => {string => undef, initial => undef},
      basenamestring => 'Doe',
      namestring     => 'Doe',
      nameinitstring => 'Doe' } ;

is_deeply(Biber::Input::file::bibtex::parsename_x('given=John,family=Doe', 'author', {uniquename => 0}), $name1, 'parsename_x 1');
is_deeply(Biber::Input::file::bibtex::parsename_x('family=Doe, suffix=Jr, given=John, given-i=J', 'author', {uniquename => 0}), $name2, 'parsename_x 2');
is_deeply(Biber::Input::file::bibtex::parsename_x('prefix=von, family=Berlichingen zu Hornberg, given=Johann Gottfried', 'author', {useprefix => 1, uniquename => 0}), $name3, 'parsename_x 3') ;
is_deeply(Biber::Input::file::bibtex::parsename_x('prefix=von, family=Berlichingen zu Hornberg, given=Johann Gottfried', 'author', {useprefix => 0, uniquename => 0}), $name4, 'parsename_x 4') ;
is_deeply(Biber::Input::file::bibtex::parsename_x('"family={Robert and Sons, Inc.}"', 'author', {uniquename => 0}), $name5, 'parsename_x 5') ;
is_deeply(Biber::Input::file::bibtex::parsename_x('family=al-Ṣāliḥ, given=ʿAbdallāh', 'author', {uniquename => 0}, 1), $name6, 'parsename_x 6') ;
is_deeply(Biber::Input::file::bibtex::parsename_x('given=Jean Charles Gabriel, prefix=de la, family=Vallée Poussin', 'author', {useprefix => 1, uniquename => 0}), $name7, 'parsename_x 7');
is_deeply(Biber::Input::file::bibtex::parsename_x('given={Jean Charles Gabriel}, prefix=de la, family=Vallée Poussin', 'author', {uniquename => 0}), $name8, 'parsename_x 8');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=Jean Charles Gabriel de la Vallée, given-i=JCGdV, family=Poussin', 'author', {uniquename => 0}), $name9, 'parsename_x 9');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=Jean Charles Gabriel, prefix=de la, family={Vallée Poussin}', 'author', {uniquename => 0}, 1), $name10, 'parsename_x 10');
is_deeply(Biber::Input::file::bibtex::parsename_x('given={Jean Charles Gabriel}, prefix=de la, family={Vallée Poussin}', 'author', {uniquename => 0}), $name11, 'parsename_x 11');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=Jean Charles Gabriel, family=Poussin', 'author', {uniquename => 0}), $name12, 'parsename_x 12');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=Jean Charles, family={Poussin Lecoq}', 'author', {uniquename => 0}), $name13, 'parsename_x 13');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=J. C. G., prefix=de la, family=Vallée Poussin', 'author', {useprefix => 1, uniquename => 0}, 1), $name14, 'parsename_x 14');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=E. S., family=El-Mallah', 'author', {uniquename => 0}), $name15, 'parsename_x 15');
is_deeply(Biber::Input::file::bibtex::parsename_x('given=E. S., family=Kent-Boswell', 'author', {uniquename => 0}), $name16, 'parsename_x 16');
is_deeply(Biber::Input::file::bibtex::parsename_x('family=Other, given=A.~N.', 'author', {uniquename => 0}), $name17, 'parsename_x 17');
is_deeply(Biber::Input::file::bibtex::parsename_x('family={British National Corpus}', 'author', {uniquename => 0}), $name18, 'parsename_x 18');
is_deeply(Biber::Input::file::bibtex::parsename_x('sortnamekeyscheme=test, family=Smith, given=Bill', 'author', {uniquename => 0}), $name19, 'parsename_x 19');
is_deeply(Biber::Input::file::bibtex::parsename_x('family=Doe, family-i={Do}', 'author', {uniquename => 0}), $name20, 'parsename_x 20');

