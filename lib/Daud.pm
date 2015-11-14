package Daud;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Daud ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	get_style set_style lose_data recode get_styles daudify
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.0.1';

my $maps = { ascii => {},
	html => {},
	latin1 => {},
	postscript => {},
	unicode => {},
	lossy => {},
	Etab => {},
	Ctab => {},
	};

foreach (_raw_data())
{
	next if /^#/;
	chomp;
	my ($daud, $ascii, $unicode, $html, $name) = split(/;/, $_);
	$maps->{ascii}->{$daud} = $ascii;
	$maps->{html}->{$daud} = "$html;" if $html;
	$maps->{unicode}->{$daud} = "#$unicode;";
	$unicode = hex($unicode);
	if ($unicode < 256)
	{
		$maps->{latin1}->{$daud} = pack('C', $unicode);
		$maps->{postscript}->{$daud} = pack('C', $unicode);
	}
	else
	{
		$maps->{lossy}->{$daud} = 1;
		$maps->{latin1}->{$daud} = $ascii;
		$maps->{postscript}->{$daud} = $ascii;
		$maps->{postscript}->{$daud} = "\201" if $daud eq 'cv';
		$maps->{postscript}->{$daud} = "\202" if $daud eq 'OE';
		$maps->{postscript}->{$daud} = "\203" if $daud eq 'oe';
		$maps->{postscript}->{$daud} = "\204" if $daud eq 'Sv';
		$maps->{postscript}->{$daud} = "\205" if $daud eq 'sv';
	}
	
	if ($html =~ m{ \A [&] ([A-Za-z0-9_]+) \z}xms)
	{
	    $maps->{Etab}->{$1} = "{$daud}";
	}
	
	if ($unicode >= 127 and $unicode <= 255)
	{
	    $maps->{Ctab}->{$unicode} = "{$daud}";
	}
}

# Preloaded methods go here.

{
	my @styles = qw / ascii latin1 html postscript unicode /;
	my $style = 'ascii';
	sub get_style { return $style;}
	
	sub set_style
	{
		my $newstyle = shift;
		return undef unless grep(/^$newstyle$/, @styles);
		$style = $newstyle;
	}
	
	sub get_styles { return wantarray ? @styles : [@styles];}
}
sub lose_data # true means data loss
{
	my $string = shift;
	my $map = $maps->{get_style()};
	return 0 unless $string; # empty/null/undef has no data to lose
	return 0 unless $string =~ /\{/; # no Daud code -> no data to lose
	return 1 if get_style eq 'ascii'; # ascii inherently loses data
	while ($string =~ /\{(..?)\}/g)
	{
		my $daud = $1;
		return 1 unless exists $map->{$daud}; # no mapping -> lost data
		next unless $maps->{lossy}->{$daud}; # probable data loss
		# if mapping is same as ascii, data loss.
		return 1 if $maps->{ascii}->{$daud} eq $map->{$daud}; 
	}
        return 0;
}

sub recode
{
	# most of this code ripped straight from Text::Unidecode::unidecode
  # Destructive in void context -- in other contexts, nondestructive.

  unless(@_) {
    # Nothing coming in
    return() if wantarray;
    return '';
  }
  @_ = map $_, @_ if defined wantarray;
   # We're in list or scalar context, NOT void context.
   #  So make @_'s items no longer be aliases.
   # Otherwise, let @_ be aliases, and alter in-place.
   
   my $map = $maps->{get_style()};

  foreach my $x (@_) {
    next unless defined $x;
	$x =~ s:\{(..?)\}:$map->{$1}:ges;
  }

  return unless defined wantarray; # void context
  return @_ if wantarray;  # normal list context -- return the copies
  # Else normal scalar context:
  return $_[0] if @_ == 1;
  return join '', @_;      # rarer fallthru: a list in, but a scalar out.
}

    sub daudify {
        my $string = shift;
        
        $string = '' if not defined $string;
        $string =~ s{ & ([A-Za-z0-9_]+) ; }
        { $maps->{Etab}->{$1} || { carp "Unknown entity $1 in $string", '.'}
        }egxsm;
        
        $string =~ s{ & [#] (.+) ; }
        { $maps->{Ctab}->{$1} || { carp "Illegal character $1 in $string", '.'}
        }egxsm;
        
        $string =~ s{ ([\000-\011\013\014\016-\037?\177-\377]) }
        { $maps->{Ctab}->{ord($1)} || {carp "Illegal character $1 in $string", '.' }
        }egxsm;
        
        return $string;
    }

1;
#__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Daud - Perl extension converting between Daud encoding and other styles

=head1 SYNOPSIS

  use Daud;
  

=head1 DESCRIPTION

Converts from Daud encoding to ASCII, Latin-1, HTML entity, Postscript,
and Unicode representations. Some conversions are lossy.

Daud encoding provides a typewriter-safe way to represent characters
not present on a standard American typewriter keyboard. Such characters
typically have accents, or are ligatures of some sort. Note that this
precludes the use of ` (backtick).

Character encodings are (typically) two characters within curly braces.
One is the underlying letter, and the other represents the accent mark.

For example, e-acute is {e'} and C-cedilla is {C,}. 

For a grave accent, put the quote before the letter as in e-grave {'e}.

Ash, edh and thorn are {AE}/{ae}, {Dh}/{dh}, and {Th}/{th}.

The accent indicators are:

=over 4

=item ' - acute accent (after) or grave accent (before)

=item ^ - circumflex

=item ~ - tilde

=item : - umlaut/diaresis

=item o - ring

=item , - cedilla/ogonek

=item / - stroke

=item - - macron/topbar

=item v - hacek/caron

=item u - breve

=item " - double grave (before) or double acute (after)

=item n - inverted breve

=item . - dot; dot before is DOT ABOVE; dot after is DOT BELOW

=back

=head2 EXPORT

Nothing by default. The following routines are exported on demand.

=over 4

=item get_style

Return the current target representation. By default, this is "ascii".

=item set_style(style)

Set the target representation. Acceptable values of style are:

  ascii - ASCII characters only
  latin1 - ISO 8859-1 (Latin-1) characters
  html - HTML named entities
  postscript - Postscript characters
  unicode - Unicode characters

Returns undef if style is not valid. Returns the new style otherwise.

=item get_styles

Return a list of acceptable styles. The list is in no particular order.

=item lose_data(string)

Returns TRUE if converting the string to the target style will cause
data loss.

=item recode(string)

Converts the string to the target style. If called in a void context,
modifies the string in place, otherwise returns the modified string.

=item daudify(string)

Converts the string to Da'ud notation. Named entities, ampersand-escaped
hex characters, and hi-bit characters are each converted. A warning is
thrown for each unrecognizable character encountered.

Returns the converted string.

=back

=head1 AUTHOR

Michael Houghton, C<< <herveus at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Michael Houghton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 TODO

Conversion to Daud from appropriate input character sets (Latin1,
HTML entity, and Unicode come to mind).

=cut

sub _raw_data {
return split(/\n/, <<EOD);
#Daud code; old encoding; unicode hex code; html entity; unicode name
'A;A;00C0;&Agrave;LATIN CAPITAL LETTER A WITH GRAVE
A';A;00C1;&Aacute;LATIN CAPITAL LETTER A WITH ACUTE
A^;A;00C2;&Acirc;LATIN CAPITAL LETTER A WITH CIRCUMFLEX
A~;A;00C3;&Atilde;LATIN CAPITAL LETTER A WITH TILDE
A:;A;00C4;&Auml;LATIN CAPITAL LETTER A WITH DIAERESIS
Ao;Aa;00C5;&Aring;LATIN CAPITAL LETTER A WITH RING ABOVE
AE;AE;00C6;&AElig;LATIN CAPITAL LIGATURE AE
C,;C;00C7;&Ccedil;LATIN CAPITAL LETTER C WITH CEDILLA
'E;E;00C8;&Egrave;LATIN CAPITAL LETTER E WITH GRAVE
E';E;00C9;&Eacute;LATIN CAPITAL LETTER E WITH ACUTE
E^;E;00CA;&Ecirc;LATIN CAPITAL LETTER E WITH CIRCUMFLEX
E:;E;00CB;&Euml;LATIN CAPITAL LETTER E WITH DIAERESIS
'I;I;00CC;&Igrave;LATIN CAPITAL LETTER I WITH GRAVE
I';I;00CD;&Iacute;LATIN CAPITAL LETTER I WITH ACUTE
I^;I;00CE;&Icirc;LATIN CAPITAL LETTER I WITH CIRCUMFLEX
I:;I;00CF;&Iuml;LATIN CAPITAL LETTER I WITH DIAERESIS
Dh;Dh;00D0;&ETH;LATIN CAPITAL LETTER ETH
N~;N;00D1;&Ntilde;LATIN CAPITAL LETTER N WITH TILDE
'O;O;00D2;&Ograve;LATIN CAPITAL LETTER O WITH GRAVE
O';O;00D3;&Oacute;LATIN CAPITAL LETTER O WITH ACUTE
O^;O;00D4;&Ocirc;LATIN CAPITAL LETTER O WITH CIRCUMFLEX
O~;O;00D5;&Otilde;LATIN CAPITAL LETTER O WITH TILDE
O:;O;00D6;&Ouml;LATIN CAPITAL LETTER O WITH DIAERESIS
O/;OE;00D8;&Oslash;LATIN CAPITAL LETTER O WITH STROKE
'U;U;00D9;&Ugrave;LATIN CAPITAL LETTER U WITH GRAVE
U';U;00DA;&Uacute;LATIN CAPITAL LETTER U WITH ACUTE
U^;U;00DB;&Ucirc;LATIN CAPITAL LETTER U WITH CIRCUMFLEX
U:;U;00DC;&Uuml;LATIN CAPITAL LETTER U WITH DIAERESIS
Y';Y;00DD;&Yacute;LATIN CAPITAL LETTER Y WITH ACUTE
Th;Th;00DE;&THORN;LATIN CAPITAL LETTER THORN
sz;sz;00DF;&szlig;LATIN SMALL LETTER SHARP S
'a;a;00E0;&agrave;LATIN SMALL LETTER A WITH GRAVE
a';a;00E1;&aacute;LATIN SMALL LETTER A WITH ACUTE
a^;a;00E2;&acirc;LATIN SMALL LETTER A WITH CIRCUMFLEX
a~;a;00E3;&atilde;LATIN SMALL LETTER A WITH TILDE
a:;a;00E4;&auml;LATIN SMALL LETTER A WITH DIAERESIS
ao;aa;00E5;&aring;LATIN SMALL LETTER A WITH RING ABOVE
ae;ae;00E6;&aelig;LATIN SMALL LIGATURE AE
c,;c;00E7;&ccedil;LATIN SMALL LETTER C WITH CEDILLA
'e;e;00E8;&egrave;LATIN SMALL LETTER E WITH GRAVE
e';e;00E9;&eacute;LATIN SMALL LETTER E WITH ACUTE
e^;e;00EA;&ecirc;LATIN SMALL LETTER E WITH CIRCUMFLEX
e:;e;00EB;&euml;LATIN SMALL LETTER E WITH DIAERESIS
'i;i;00EC;&igrave;LATIN SMALL LETTER I WITH GRAVE
i';i;00ED;&iacute;LATIN SMALL LETTER I WITH ACUTE
i^;i;00EE;&icirc;LATIN SMALL LETTER I WITH CIRCUMFLEX
i:;i;00EF;&iuml;LATIN SMALL LETTER I WITH DIAERESIS
dh;dh;00F0;&eth;LATIN SMALL LETTER ETH
n~;n;00F1;&ntilde;LATIN SMALL LETTER N WITH TILDE
'o;o;00F2;&ograve;LATIN SMALL LETTER O WITH GRAVE
o';o;00F3;&oacute;LATIN SMALL LETTER O WITH ACUTE
o^;o;00F4;&ocirc;LATIN SMALL LETTER O WITH CIRCUMFLEX
o~;o;00F5;&otilde;LATIN SMALL LETTER O WITH TILDE
o:;o;00F6;&ouml;LATIN SMALL LETTER O WITH DIAERESIS
o/;oe;00F8;&oslash;LATIN SMALL LETTER O WITH STROKE
'u;u;00F9;&ugrave;LATIN SMALL LETTER U WITH GRAVE
u';u;00FA;&uacute;LATIN SMALL LETTER U WITH ACUTE
u^;u;00FB;&ucirc;LATIN SMALL LETTER U WITH CIRCUMFLEX
u:;u;00FC;&uuml;LATIN SMALL LETTER U WITH DIAERESIS
y';y;00FD;&yacute;LATIN SMALL LETTER Y WITH ACUTE
th;th;00FE;&thorn;LATIN SMALL LETTER THORN
y:;y;00FF;&yuml;LATIN SMALL LETTER Y WITH DIAERESIS
A-;A;0100;;LATIN CAPITAL LETTER A WITH MACRON
a-;a;0101;&amacr;LATIN SMALL LETTER A WITH MACRON
Au;A;0102;;LATIN CAPITAL LETTER A WITH BREVE
au;a;0103;;LATIN SMALL LETTER A WITH BREVE
A,;A;0104;;LATIN CAPITAL LETTER A WITH OGONEK
a,;a;0105;;LATIN SMALL LETTER A WITH OGONEK
C';C;0106;;LATIN CAPITAL LETTER C WITH ACUTE
c';c;0107;;LATIN SMALL LETTER C WITH ACUTE
C^;C;0108;;LATIN CAPITAL LETTER C WITH CIRCUMFLEX
c^;c;0109;;LATIN SMALL LETTER C WITH CIRCUMFLEX
Cv;C;010C;;LATIN CAPITAL LETTER C WITH CARON
cv;c;010D;;LATIN SMALL LETTER C WITH CARON
Dv;D;010E;;LATIN CAPITAL LETTER D WITH CARON
dv;d;010F;;LATIN SMALL LETTER D WITH CARON
D/;D;0110;;LATIN CAPITAL LETTER D WITH STROKE
d/;d;0111;;LATIN SMALL LETTER D WITH STROKE
E-;E;0112;;LATIN CAPITAL LETTER E WITH MACRON
e-;e;0113;;LATIN SMALL LETTER E WITH MACRON
Eu;E;0114;;LATIN CAPITAL LETTER E WITH BREVE
eu;e;0115;;LATIN SMALL LETTER E WITH BREVE
.E;E;0116;;LATIN CAPITAL LETTER E WITH DOT ABOVE
.e;e;0117;;LATIN SMALL LETTER E WITH DOT ABOVE
E,;E;0118;;LATIN CAPITAL LETTER E WITH OGONEK
e,;e;0119;;LATIN SMALL LETTER E WITH OGONEK
Ev;E;011A;;LATIN CAPITAL LETTER E WITH CARON
ev;e;011B;;LATIN SMALL LETTER E WITH CARON
G^;G;011C;;LATIN CAPITAL LETTER G WITH CIRCUMFLEX
g^;g;011D;;LATIN SMALL LETTER G WITH CIRCUMFLEX
Gu;G;011E;;LATIN CAPITAL LETTER G WITH BREVE
gu;g;011F;;LATIN SMALL LETTER G WITH BREVE
G,;G;0122;;LATIN CAPITAL LETTER G WITH CEDILLA
g,;g;0123;;LATIN SMALL LETTER G WITH CEDILLA
H^;H;0124;;LATIN CAPITAL LETTER H WITH CIRCUMFLEX
h^;h;0125;;LATIN SMALL LETTER H WITH CIRCUMFLEX
H/;H;0126;;LATIN CAPITAL LETTER H WITH STROKE
h/;h;0127;;LATIN SMALL LETTER H WITH STROKE
I~;I;0128;;LATIN CAPITAL LETTER I WITH TILDE
i~;i;0129;;LATIN SMALL LETTER I WITH TILDE
I-;I;012A;;LATIN CAPITAL LETTER I WITH MACRON
i-;i;012B;;LATIN SMALL LETTER I WITH MACRON
Iu;I;012C;;LATIN CAPITAL LETTER I WITH BREVE
iu;i;012D;;LATIN SMALL LETTER I WITH BREVE
I,;I;012E;;LATIN CAPITAL LETTER I WITH OGONEK
i,;i;012F;;LATIN SMALL LETTER I WITH OGONEK
.I;I;0130;;LATIN CAPITAL LETTER I WITH DOT ABOVE
i;i;0131;;LATIN SMALL LETTER DOTLESS I
IJ;IJ;0132;;LATIN CAPITAL LIGATURE IJ
ij;ij;0133;;LATIN SMALL LIGATURE IJ
J^;J;0134;;LATIN CAPITAL LETTER J WITH CIRCUMFLEX
j^;j;0135;;LATIN SMALL LETTER J WITH CIRCUMFLEX
K,;K;0136;;LATIN CAPITAL LETTER K WITH CEDILLA
k,;k;0137;;LATIN SMALL LETTER K WITH CEDILLA
L';L;0139;;LATIN CAPITAL LETTER L WITH ACUTE
l';l;013A;;LATIN SMALL LETTER L WITH ACUTE
L,;L;013B;;LATIN CAPITAL LETTER L WITH CEDILLA
l,;l;013C;;LATIN SMALL LETTER L WITH CEDILLA
Lv;L;013D;;LATIN CAPITAL LETTER L WITH CARON
lv;l;013E;;LATIN SMALL LETTER L WITH CARON
L/;L;0141;;LATIN CAPITAL LETTER L WITH STROKE
l/;l;0142;;LATIN SMALL LETTER L WITH STROKE
N';N;0143;;LATIN CAPITAL LETTER N WITH ACUTE
n';n;0144;;LATIN SMALL LETTER N WITH ACUTE
N,;N;0145;;LATIN CAPITAL LETTER N WITH CEDILLA
n,;n;0146;;LATIN SMALL LETTER N WITH CEDILLA
Nv;N;0147;;LATIN CAPITAL LETTER N WITH CARON
nv;n;0148;;LATIN SMALL LETTER N WITH CARON
Ng;Ng;014A;;LATIN CAPITAL LETTER ENG
ng;ng;014B;;LATIN SMALL LETTER ENG
O-;O;014C;;LATIN CAPITAL LETTER O WITH MACRON
o-;o;014D;;LATIN SMALL LETTER O WITH MACRON
Ou;O;014E;;LATIN CAPITAL LETTER O WITH BREVE
ou;o;014F;;LATIN SMALL LETTER O WITH BREVE
O";O;0150;;LATIN CAPITAL LETTER O WITH DOUBLE ACUTE
o";o;0151;;LATIN SMALL LETTER O WITH DOUBLE ACUTE
OE;OE;0152;&OElig;LATIN CAPITAL LIGATURE OE
oe;oe;0153;&oelig;LATIN SMALL LIGATURE OE
R';R;0154;;LATIN CAPITAL LETTER R WITH ACUTE
r';r;0155;;LATIN SMALL LETTER R WITH ACUTE
R,;R;0156;;LATIN CAPITAL LETTER R WITH CEDILLA
r,;r;0157;;LATIN SMALL LETTER R WITH CEDILLA
Rv;R;0158;;LATIN CAPITAL LETTER R WITH CARON
rv;r;0159;;LATIN SMALL LETTER R WITH CARON
S';S;015A;;LATIN CAPITAL LETTER S WITH ACUTE
s';s;015B;;LATIN SMALL LETTER S WITH ACUTE
S^;S;015C;;LATIN CAPITAL LETTER S WITH CIRCUMFLEX
s^;s;015D;;LATIN SMALL LETTER S WITH CIRCUMFLEX
S,;S;015E;;LATIN CAPITAL LETTER S WITH CEDILLA
s,;s;015F;;LATIN SMALL LETTER S WITH CEDILLA
Sv;S;0160;&Scaron;LATIN CAPITAL LETTER S WITH CARON
sv;s;0161;&scaron;LATIN SMALL LETTER S WITH CARON
T,;T;0162;;LATIN CAPITAL LETTER T WITH CEDILLA
t,;t;0163;;LATIN SMALL LETTER T WITH CEDILLA
Tv;T;0164;;LATIN CAPITAL LETTER T WITH CARON
tv;t;0165;;LATIN SMALL LETTER T WITH CARON
T/;T;0166;;LATIN CAPITAL LETTER T WITH STROKE
t/;t;0167;;LATIN SMALL LETTER T WITH STROKE
U~;U;0168;;LATIN CAPITAL LETTER U WITH TILDE
u~;u;0169;;LATIN SMALL LETTER U WITH TILDE
U-;U;016A;;LATIN CAPITAL LETTER U WITH MACRON
u-;u;016B;;LATIN SMALL LETTER U WITH MACRON
Uu;U;016C;;LATIN CAPITAL LETTER U WITH BREVE
uu;u;016D;;LATIN SMALL LETTER U WITH BREVE
Uo;U;016E;;LATIN CAPITAL LETTER U WITH RING ABOVE
uo;u;016F;;LATIN SMALL LETTER U WITH RING ABOVE
U";U;0170;;LATIN CAPITAL LETTER U WITH DOUBLE ACUTE
u";u;0171;;LATIN SMALL LETTER U WITH DOUBLE ACUTE
U,;U;0172;;LATIN CAPITAL LETTER U WITH OGONEK
u,;u;0173;;LATIN SMALL LETTER U WITH OGONEK
W^;W;0174;;LATIN CAPITAL LETTER W WITH CIRCUMFLEX
w^;w;0175;;LATIN SMALL LETTER W WITH CIRCUMFLEX
Y^;Y;0176;;LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
y^;y;0177;;LATIN SMALL LETTER Y WITH CIRCUMFLEX
Y:;Y;0178;&Yuml;LATIN CAPITAL LETTER Y WITH DIAERESIS
Z';Z;0179;;LATIN CAPITAL LETTER Z WITH ACUTE
z';z;017A;;LATIN SMALL LETTER Z WITH ACUTE
.Z;Z;017B;;LATIN CAPITAL LETTER Z WITH DOT ABOVE
.z;z;017C;;LATIN SMALL LETTER Z WITH DOT ABOVE
Zv;Z;017D;;LATIN CAPITAL LETTER Z WITH CARON
zv;z;017E;&zcaron;LATIN SMALL LETTER Z WITH CARON
b/;b;0180;;LATIN SMALL LETTER B WITH STROKE
B-;Bh;0182;;LATIN CAPITAL LETTER B WITH TOPBAR
b-;bh;0183;;LATIN SMALL LETTER B WITH TOPBAR
D-;Dh;018B;;LATIN CAPITAL LETTER D WITH TOPBAR
d-;dh;018C;;LATIN SMALL LETTER D WITH TOPBAR
I/;I;0197;;LATIN CAPITAL LETTER I WITH STROKE
Z/;Z;01B5;;LATIN CAPITAL LETTER Z WITH STROKE
z/;z;01B6;;LATIN SMALL LETTER Z WITH STROKE
Zh;Zh;01B7;;LATIN CAPITAL LETTER EZH
Av;A;01CD;;LATIN CAPITAL LETTER A WITH CARON
av;a;01CE;;LATIN SMALL LETTER A WITH CARON
Iv;I;01CF;;LATIN CAPITAL LETTER I WITH CARON
iv;i;01D0;;LATIN SMALL LETTER I WITH CARON
Ov;O;01D1;;LATIN CAPITAL LETTER O WITH CARON
ov;o;01D2;;LATIN SMALL LETTER O WITH CARON
Uv;U;01D3;;LATIN CAPITAL LETTER U WITH CARON
uv;u;01D4;;LATIN SMALL LETTER U WITH CARON
G/;G;01E4;;LATIN CAPITAL LETTER G WITH STROKE
g/;g;01E5;;LATIN SMALL LETTER G WITH STROKE
Gv;G;01E6;;LATIN CAPITAL LETTER G WITH CARON
gv;g;01E7;;LATIN SMALL LETTER G WITH CARON
Kv;K;01E8;;LATIN CAPITAL LETTER K WITH CARON
kv;k;01E9;;LATIN SMALL LETTER K WITH CARON
O,;O;01EA;;LATIN CAPITAL LETTER O WITH OGONEK
o,;o;01EB;;LATIN SMALL LETTER O WITH OGONEK
jv;j;01F0;;LATIN SMALL LETTER J WITH CARON
G';G;01F4;;LATIN CAPITAL LETTER G WITH ACUTE
g';g;01F5;;LATIN SMALL LETTER G WITH ACUTE
"A;A;0200;;LATIN CAPITAL LETTER A WITH DOUBLE GRAVE
"a;a;0201;;LATIN SMALL LETTER A WITH DOUBLE GRAVE
An;A;0202;;LATIN CAPITAL LETTER A WITH INVERTED BREVE
an;a;0203;;LATIN SMALL LETTER A WITH INVERTED BREVE
"E;E;0204;;LATIN CAPITAL LETTER E WITH DOUBLE GRAVE
"e;e;0205;;LATIN SMALL LETTER E WITH DOUBLE GRAVE
En;E;0206;;LATIN CAPITAL LETTER E WITH INVERTED BREVE
en;e;0207;;LATIN SMALL LETTER E WITH INVERTED BREVE
"I;I;0208;;LATIN CAPITAL LETTER I WITH DOUBLE GRAVE
"i;i;0209;;LATIN SMALL LETTER I WITH DOUBLE GRAVE
In;I;020A;;LATIN CAPITAL LETTER I WITH INVERTED BREVE
in;i;020B;;LATIN SMALL LETTER I WITH INVERTED BREVE
"O;O;020C;;LATIN CAPITAL LETTER O WITH DOUBLE GRAVE
"o;o;020D;;LATIN SMALL LETTER O WITH DOUBLE GRAVE
On;O;020E;;LATIN CAPITAL LETTER O WITH INVERTED BREVE
on;o;020F;;LATIN SMALL LETTER O WITH INVERTED BREVE
"R;R;0210;;LATIN CAPITAL LETTER R WITH DOUBLE GRAVE
"r;r;0211;;LATIN SMALL LETTER R WITH DOUBLE GRAVE
Rn;R;0212;;LATIN CAPITAL LETTER R WITH INVERTED BREVE
rn;r;0213;;LATIN SMALL LETTER R WITH INVERTED BREVE
"U;U;0214;;LATIN CAPITAL LETTER U WITH DOUBLE GRAVE
"u;u;0215;;LATIN SMALL LETTER U WITH DOUBLE GRAVE
Un;U;0216;;LATIN CAPITAL LETTER U WITH INVERTED BREVE
un;u;0217;;LATIN SMALL LETTER U WITH INVERTED BREVE
Gh;3;021C;;LATIN CAPITAL LETTER YOGH
3;3;021D;;LATIN SMALL LETTER YOGH
gh;3;021D;;LATIN SMALL LETTER YOGH
i/;i;0268;;LATIN SMALL LETTER I WITH STROKE
zh;zh;0292;;LATIN SMALL LETTER EZH
Ph;Ph;03A6;;GREEK CAPITAL LETTER PHI
Ps;Ps;03A8;;GREEK CAPITAL LETTER PSI
rh;rh;03C1;;GREEK SMALL LETTER RHO
ph;ph;03C6;;GREEK SMALL LETTER PHI
ch;ch;03C7;;GREEK SMALL LETTER CHI
ps;ps;03C8;;GREEK SMALL LETTER PSI
B.;B;1E04;;LATIN CAPITAL LETTER B WITH DOT BELOW
b.;b;1E05;;LATIN SMALL LETTER B WITH DOT BELOW
B_;B;1E06;;LATIN CAPITAL LETTER B WITH LINE BELOW
b_;b;1E07;;LATIN SMALL LETTER B WITH LINE BELOW
D.;D;1E0C;;LATIN CAPITAL LETTER D WITH DOT BELOW
d.;d;1E0D;;LATIN SMALL LETTER D WITH DOT BELOW
D_;D;1E0E;;LATIN CAPITAL LETTER D WITH LINE BELOW
d_;d;1E0F;;LATIN SMALL LETTER D WITH LINE BELOW
D,;D;1E10;;LATIN CAPITAL LETTER D WITH CEDILLA
d,;d;1E11;;LATIN SMALL LETTER D WITH CEDILLA
G-;G;1E20;;LATIN CAPITAL LETTER G WITH MACRON
g-;g;1E21;;LATIN SMALL LETTER G WITH MACRON
H.;H;1E24;;LATIN CAPITAL LETTER H WITH DOT BELOW
h.;h;1E25;;LATIN SMALL LETTER H WITH DOT BELOW
H:;H;1E26;;LATIN CAPITAL LETTER H WITH DIAERESIS
h:;h;1E27;;LATIN SMALL LETTER H WITH DIAERESIS
H,;H;1E28;;LATIN CAPITAL LETTER H WITH CEDILLA
h,;h;1E29;;LATIN SMALL LETTER H WITH CEDILLA
K';K;1E30;;LATIN CAPITAL LETTER K WITH ACUTE
k';k;1E31;;LATIN SMALL LETTER K WITH ACUTE
K.;K;1E32;;LATIN CAPITAL LETTER K WITH DOT BELOW
k.;k;1E33;;LATIN SMALL LETTER K WITH DOT BELOW
K_;K;1E34;;LATIN CAPITAL LETTER K WITH LINE BELOW
k_;k;1E35;;LATIN SMALL LETTER K WITH LINE BELOW
L.;L;1E36;;LATIN CAPITAL LETTER L WITH DOT BELOW
l.;l;1E37;;LATIN SMALL LETTER L WITH DOT BELOW
L_;L;1E3A;;LATIN CAPITAL LETTER L WITH LINE BELOW
l_;l;1E3B;;LATIN SMALL LETTER L WITH LINE BELOW
M';M;1E3E;;LATIN CAPITAL LETTER M WITH ACUTE
m';m;1E3F;;LATIN SMALL LETTER M WITH ACUTE
M.;M;1E42;;LATIN CAPITAL LETTER M WITH DOT BELOW
m.;m;1E43;;LATIN SMALL LETTER M WITH DOT BELOW
N.;N;1E46;;LATIN CAPITAL LETTER N WITH DOT BELOW
n.;n;1E47;;LATIN SMALL LETTER N WITH DOT BELOW
N_;N;1E48;;LATIN CAPITAL LETTER N WITH LINE BELOW
n_;n;1E49;;LATIN SMALL LETTER N WITH LINE BELOW
P';P;1E54;;LATIN CAPITAL LETTER P WITH ACUTE
p';p;1E55;;LATIN SMALL LETTER P WITH ACUTE
R.;R;1E5A;;LATIN CAPITAL LETTER R WITH DOT BELOW
r.;r;1E5B;;LATIN SMALL LETTER R WITH DOT BELOW
R_;R;1E5E;;LATIN CAPITAL LETTER R WITH LINE BELOW
r_;r;1E5F;;LATIN SMALL LETTER R WITH LINE BELOW
S.;S;1E62;;LATIN CAPITAL LETTER S WITH DOT BELOW
s.;s;1E63;;LATIN SMALL LETTER S WITH DOT BELOW
T.;T;1E6C;;LATIN CAPITAL LETTER T WITH DOT BELOW
t.;t;1E6D;;LATIN SMALL LETTER T WITH DOT BELOW
T_;T;1E6E;;LATIN CAPITAL LETTER T WITH LINE BELOW
t_;t;1E6F;;LATIN SMALL LETTER T WITH LINE BELOW
V~;V;1E7C;;LATIN CAPITAL LETTER V WITH TILDE
v~;v;1E7D;;LATIN SMALL LETTER V WITH TILDE
V.;V;1E7E;;LATIN CAPITAL LETTER V WITH DOT BELOW
v.;v;1E7F;;LATIN SMALL LETTER V WITH DOT BELOW
'W;W;1E80;;LATIN CAPITAL LETTER W WITH GRAVE
'w;w;1E81;;LATIN SMALL LETTER W WITH GRAVE
W';W;1E82;;LATIN CAPITAL LETTER W WITH ACUTE
w';w;1E83;;LATIN SMALL LETTER W WITH ACUTE
W:;W;1E84;;LATIN CAPITAL LETTER W WITH DIAERESIS
w:;w;1E85;;LATIN SMALL LETTER W WITH DIAERESIS
W.;W;1E88;;LATIN CAPITAL LETTER W WITH DOT BELOW
w.;w;1E89;;LATIN SMALL LETTER W WITH DOT BELOW
X:;X;1E8C;;LATIN CAPITAL LETTER X WITH DIAERESIS
x:;x;1E8D;;LATIN SMALL LETTER X WITH DIAERESIS
Z^;Z;1E90;;LATIN CAPITAL LETTER Z WITH CIRCUMFLEX
z^;z;1E91;;LATIN SMALL LETTER Z WITH CIRCUMFLEX
Z.;Z;1E92;;LATIN CAPITAL LETTER Z WITH DOT BELOW
z.;z;1E93;;LATIN SMALL LETTER Z WITH DOT BELOW
Z_;Z;1E94;;LATIN CAPITAL LETTER Z WITH LINE BELOW
z_;z;1E95;;LATIN SMALL LETTER Z WITH LINE BELOW
h_;h;1E96;;LATIN SMALL LETTER H WITH LINE BELOW
t:;t;1E97;;LATIN SMALL LETTER T WITH DIAERESIS
wo;w;1E98;;LATIN SMALL LETTER W WITH RING ABOVE
yo;y;1E99;;LATIN SMALL LETTER Y WITH RING ABOVE
A.;A;1EA0;;LATIN CAPITAL LETTER A WITH DOT BELOW
a.;a;1EA1;;LATIN SMALL LETTER A WITH DOT BELOW
E.;E;1EB8;;LATIN CAPITAL LETTER E WITH DOT BELOW
e.;e;1EB9;;LATIN SMALL LETTER E WITH DOT BELOW
E~;E;1EBC;;LATIN CAPITAL LETTER E WITH TILDE
e~;e;1EBD;;LATIN SMALL LETTER E WITH TILDE
I.;I;1ECA;;LATIN CAPITAL LETTER I WITH DOT BELOW
i.;i;1ECB;;LATIN SMALL LETTER I WITH DOT BELOW
O.;O;1ECC;;LATIN CAPITAL LETTER O WITH DOT BELOW
o.;o;1ECD;;LATIN SMALL LETTER O WITH DOT BELOW
U.;U;1EE4;;LATIN CAPITAL LETTER U WITH DOT BELOW
u.;u;1EE5;;LATIN SMALL LETTER U WITH DOT BELOW
'Y;Y;1EF2;;LATIN CAPITAL LETTER Y WITH GRAVE
'y;y;1EF3;;LATIN SMALL LETTER Y WITH GRAVE
Y.;Y;1EF4;;LATIN CAPITAL LETTER Y WITH DOT BELOW
y.;y;1EF5;;LATIN SMALL LETTER Y WITH DOT BELOW
Y~;Y;1EF8;;LATIN CAPITAL LETTER Y WITH TILDE
y~;y;1EF9;;LATIN SMALL LETTER Y WITH TILDE
ff;ff;FB00;;LATIN SMALL LIGATURE FF
fi;fi;FB01;;LATIN SMALL LIGATURE FI
fl;fl;FB02;;LATIN SMALL LIGATURE FL
st;st;FB06;;LATIN SMALL LIGATURE ST
u!;u;E724;&uvertline;LATIN SMALL LETTER U WITH VERTICAL LINE ABOVE
EOD
}

