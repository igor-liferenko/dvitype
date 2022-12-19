% This program by D. E. Knuth is not copyrighted and can be used freely.
% Version 1 was completed in September, 1982.
% Slight changes were made in October, 1982, for version 0.7 of TeX.
% Version 1.1 corrected minor bugs (May, 1983).
% Version 2 was released with version 0.999 of TeX (July, 1983).
% Version 2.1 corrected a bug when no fonts are present (September, 1983).
% Version 2.2 corrected bugs in max_*_so_far and put1 (October, 1983).
% Version 2.3 corrected spacing of accents (March, 1984).
% Version 2.4 fixed rounding, changed oriental font conventions (April, 1984).
% Version 2.5 improved the case of zero pages (May, 1984).
% Version 2.6 introduced max_drift (June, 1984).
% Version 2.7 had minor editorial changes (August, 1984).
% Version 2.8 made default resolution 300/1 (April, 1985).
% Version 2.9 changed negative scaling as in TeX version 2.7 (November, 1987).
% Version 3 introduced an intermediate level of verbosity (October,1989).
% Version 3.1 gave magnification info in final font list (November, 1989).
% Version 3.2 doublechecked design size of each font (January, 1990).
% Version 3.3 had more robust for loops in print_font, define_font (May, 1990).
% Version 3.4 more robustness in presence of bad fonts (September, 1990).
% Version 3.5 checked skipped material more strictly (March, 1995).
% Version 3.6 gives a better help message (December, 1995).

% Here is TeX material that gets inserted after \input webmac
\def\hang{\hangindent 3em\indent\ignorespaces}
\font\ninerm=cmr9
\let\mc=\ninerm % medium caps for names like SAIL
\def\PASCAL{Pascal}

\def\(#1){} % this is used to make section names sort themselves better
\def\9#1{} % this is used for sort keys in the index

\def\title{DVI$\,$\lowercase{type}}
\def\contentspagenumber{401}
\def\topofcontents{\null
  \titlefalse % include headline on the contents page
  \def\rheader{\mainfont\hfil \contentspagenumber}
  \vfill
  \centerline{\titlefont The {\ttitlefont DVItype} processor}
  \vskip 15pt
  \centerline{(Version 3.6, December 1995)}
  \vfill}
\def\botofcontents{\vfill
  \centerline{\hsize 5in\baselineskip9pt
    \vbox{\ninerm\noindent
    The preparation of this report
    was supported in part by the National Science
    Foundation under grants IST-8201926 and MCS-8300984,
    and by the System Development Foundation. `\TeX' is a
    trademark of the American Mathematical Society.}}}
\pageno=\contentspagenumber \advance\pageno by 1

@*Introduction.
The \.{DVItype} utility program reads binary device-independent (``\.{DVI}'')
files that are produced by document compilers such as \TeX, and converts them
into symbolic form. This program has two chief purposes: (1)~It can be used to
determine whether a \.{DVI} file is valid or invalid, when diagnosing
compiler errors; and (2)~it serves as an example of a program that reads
\.{DVI} files correctly, for system programmers who are developing
\.{DVI}-related software.

Goal number (2) needs perhaps a bit more explanation. Programs for
typesetting need to be especially careful about how they do arithmetic; if
rounding errors accumulate, margins won't be straight, vertical rules
won't line up, and so on. But if rounding is done everywhere, even in the
midst of words, there will be uneven spacing between the letters, and that
looks bad. Human eyes notice differences of a thousandth of an inch in the
positioning of lines that are close together; on low resolution devices,
where rounding produces effects four times as great as this, the problem
is especially critical. Experience has shown that unusual care is needed
even on high-resolution equipment; for example, a mistake in the sixth
significant hexadecimal place of a constant once led to a difficult-to-find
bug in some software for the Alphatype CRS, which has a resolution of 5333
pixels per inch (make that 5333.33333333 pixels per inch).  The document
compilers that generate \.{DVI} files make certain assumptions about the
arithmetic that will be used by \.{DVI}-reading software, and if these
assumptions are violated the results will be of inferior quality.
Therefore the present program is intended as a guide to proper procedure
in the critical places where a bit of subtlety is involved.

The first \.{DVItype} program was designed by David Fuchs in 1979, and it
@^Fuchs, David Raymond@>
went through several versions on different computers as the format of
\.{DVI} files was evolving to its present form. Peter Breitenlohner
helped with the latest revisions.
@^Breitenlohner, Peter@>

The |banner| string defined here should be changed whenever \.{DVItype}
gets modified.

@d banner	"This is DVItype, Version 3.6" /*printed when the program starts*/ 

@ This program is written in standard \PASCAL, except where it is necessary
to use extensions; for example, \.{DVItype} must read files whose names
are dynamically specified, and that would be impossible in pure \PASCAL.
All places where nonstandard constructions are used have been listed in
the index under ``system dependencies.''
@!@^system dependencies@>

One of the extensions to standard \PASCAL\ that we shall deal with is the
ability to move to a random place in a binary file; another is to
determine the length of a binary file. Such extensions are not necessary
for reading \.{DVI} files, and they are not important for efficiency
reasons either---an infrequently used program like \.{DVItype} does not
have to be efficient. But they are included there because of \.{DVItype}'s
r\^^Dole as a model of a \.{DVI} reading routine, since other \.{DVI}
processors ought to be highly efficient. If \.{DVItype} is being used with
\PASCAL s for which random file positioning is not efficiently available,
the following definition should be changed from |true| to |false|; in such
cases, \.{DVItype} will not include the optional feature that reads the
postamble first.

Another extension is to use a default |case| as in \.{TANGLE}, \.{WEAVE},
etc.

@d random_reading	true /*should we skip around in the file?*/ 
@ The binary input comes from |dvi_file|, and the symbolic output is written
on \PASCAL's standard |output| file. The term |print| is used instead of
|write| when this program writes on |output|, so that all such output
could easily be redirected if desired.

@d print(...) fprintf(output,__VA_ARGS__)
@d print_ln(X,...) fprintf(output,X"\n",##__VA_ARGS__)

@p@!@!
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define chr(X) ((unsigned char)(X))
#define abs(X) ((X)>-(X)?(X):-(X))
#define round(X) ((int)((X)>=0.0?floor((X)+0.5):ceil((X)-0.5)))

@h

#define get(file) @[fread(&((file).d),sizeof((file).d),1,(file).f)@]
#define read(file,x) @[x=file.d,get(file)@]
#define eof(file) @[(file.f==NULL||feof(file.f))@]
#define set_pos(file,n) @[fseek(file.f,n,SEEK_SET),get(file)@]
#define eoln(file) @[(file.d=='\n'||feof(file.f))@]
#define reset(file,name) @[file.f=fopen(name+1,"r"),file.f!=NULL?get(file):0@]
#define write(file,...) @[fprintf(file.f,__VA_ARGS__)@]
#define write_ln(file,X) @[write(file,X"\n")@]
#define read_ln(file) @[do { while (!eoln(file)) get(file); get(file); } while (0)@]

@<Labels in the outer block@>@;
@<Constants in the outer block@>@;
@<Types in the outer block@>@;
@<Globals in the outer block@>@;
void initialize(void) /*this procedure gets things started properly*/ 
  {@+int i; /*loop index for initializations*/ 
  print_ln(banner);@/
  @<Set initial values@>;@/
  } 

@ If the program has to stop prematurely, it goes to the
`|exit(0)|'. Another label, |done|, is used when stopping normally.

@<Labels...@>=

@ The following parameters can be changed at compile time to extend or
reduce \.{DVItype}'s capacity.

@<Constants...@>=
enum {@+@!max_fonts=100@+}; /*maximum number of distinct fonts per \.{DVI} file*/ 
enum {@+@!max_widths=10000@+}; /*maximum number of different characters among all fonts*/ 
enum {@+@!line_length=79@+}; /*bracketed lines of output will be at most this long*/ 
enum {@+@!terminal_line_length=150@+}; /*maximum number of characters input in a single
  line of input from the terminal*/ 
enum {@+@!stack_size=100@+}; /*\.{DVI} files shouldn't |push| beyond this depth*/ 
enum {@+@!name_size=1000@+}; /*total length of all font file names*/ 
enum {@+@!name_length=50@+}; /*a file name shouldn't be longer than this*/ 

@ Here are some macros for common programming idioms.

@d incr(X)	X=X+1 /*increase a variable by unity*/ 
@d decr(X)	X=X-1 /*decrease a variable by unity*/ 
@d do_nothing	 /*empty statement*/ 

@ If the \.{DVI} file is badly malformed, the whole process must be aborted;
\.{DVItype} will give up, after issuing an error message about the symptoms
that were noticed.

Such errors might be discovered inside of subroutines inside of subroutines,
so a procedure called |jump_out| has been introduced. This procedure, which
simply transfers control to the label |exit(0)| at the end of the program,
contains the only non-local |goto| statement in \.{DVItype}.
@^system dependencies@>

@d abort(...) {@+print(" "__VA_ARGS__);jump_out();
    } 
@d bad_dvi(X,...) abort("Bad DVI file: "X"!",##__VA_ARGS__)
@.Bad DVI file@>

@p void jump_out(void)
{@+exit(1);
} 

@*The character set.
Like all programs written with the  \.{WEB} system, \.{DVItype} can be
used with any character set. But it uses ASCII code internally, because
the programming for portable input-output is easier when a fixed internal
code is used, and because \.{DVI} files use ASCII code for file names
and certain other strings.

The next few sections of \.{DVItype} have therefore been copied from the
analogous ones in the \.{WEB} system routines. They have been considerably
simplified, since \.{DVItype} need not deal with the controversial
ASCII codes less than 040 or greater than 0176.
If such codes appear in the \.{DVI} file,
they will be printed as question marks.

@<Types...@>=
typedef uint8_t ASCII_code; /*a subrange of the integers*/ 

@ The original \PASCAL\ compiler was designed in the late 60s, when six-bit
character sets were common, so it did not make provision for lower case
letters. Nowadays, of course, we need to deal with both upper and lower case
alphabets in a convenient way, especially in a program like \.{DVItype}.
So we shall assume that the \PASCAL\ system being used for \.{DVItype}
has a character set containing at least the standard visible characters
of ASCII code (|'!'| through |'~'|).

Some \PASCAL\ compilers use the original name |unsigned char| for the data type
associated with the characters in text files, while other \PASCAL s
consider |unsigned char| to be a 64-element subrange of a larger data type that has
some other name.  In order to accommodate this difference, we shall use
the name |text_char| to stand for the data type of the characters in the
output file.  We shall also assume that |text_char| consists of
the elements |chr(first_text_char)| through |chr(last_text_char)|,
inclusive. The following definitions should be adjusted if necessary.
@^system dependencies@>

@d text_char	unsigned char /*the data type of characters in text files*/ 
@d first_text_char	0 /*ordinal number of the smallest element of |text_char|*/ 
@d last_text_char	127 /*ordinal number of the largest element of |text_char|*/ 

@<Types...@>=
typedef struct {@+FILE *f;@+text_char@,d;@+} text_file;

@ The \.{DVItype} processor converts between ASCII code and
the user's external character set by means of arrays |xord| and |xchr|
that are analogous to \PASCAL's |ord| and |chr| functions.

@<Globals...@>=
ASCII_code @!xord[256];
   /*specifies conversion of input characters*/ 
uint8_t @!xchr[256];
   /*specifies conversion of output characters*/ 

@ Under our assumption that the visible characters of standard ASCII are
all present, the following assignment statements initialize the
|xchr| array properly, without needing any system-dependent changes.

@<Set init...@>=
for (i=0; i<=037; i++) xchr[i]= '?' ;
xchr[040]= ' ' ;
xchr[041]= '!' ;
xchr[042]= '"' ;
xchr[043]= '#' ;
xchr[044]= '$' ;
xchr[045]= '%' ;
xchr[046]= '&' ;
xchr[047]= '\'' ;@/
xchr[050]= '(' ;
xchr[051]= ')' ;
xchr[052]= '*' ;
xchr[053]= '+' ;
xchr[054]= ',' ;
xchr[055]= '-' ;
xchr[056]= '.' ;
xchr[057]= '/' ;@/
xchr[060]= '0' ;
xchr[061]= '1' ;
xchr[062]= '2' ;
xchr[063]= '3' ;
xchr[064]= '4' ;
xchr[065]= '5' ;
xchr[066]= '6' ;
xchr[067]= '7' ;@/
xchr[070]= '8' ;
xchr[071]= '9' ;
xchr[072]= ':' ;
xchr[073]= ';' ;
xchr[074]= '<' ;
xchr[075]= '=' ;
xchr[076]= '>' ;
xchr[077]= '?' ;@/
xchr[0100]= '@@' ;
xchr[0101]= 'A' ;
xchr[0102]= 'B' ;
xchr[0103]= 'C' ;
xchr[0104]= 'D' ;
xchr[0105]= 'E' ;
xchr[0106]= 'F' ;
xchr[0107]= 'G' ;@/
xchr[0110]= 'H' ;
xchr[0111]= 'I' ;
xchr[0112]= 'J' ;
xchr[0113]= 'K' ;
xchr[0114]= 'L' ;
xchr[0115]= 'M' ;
xchr[0116]= 'N' ;
xchr[0117]= 'O' ;@/
xchr[0120]= 'P' ;
xchr[0121]= 'Q' ;
xchr[0122]= 'R' ;
xchr[0123]= 'S' ;
xchr[0124]= 'T' ;
xchr[0125]= 'U' ;
xchr[0126]= 'V' ;
xchr[0127]= 'W' ;@/
xchr[0130]= 'X' ;
xchr[0131]= 'Y' ;
xchr[0132]= 'Z' ;
xchr[0133]= '[' ;
xchr[0134]= '\\' ;
xchr[0135]= ']' ;
xchr[0136]= '^' ;
xchr[0137]= '_' ;@/
xchr[0140]= '`' ;
xchr[0141]= 'a' ;
xchr[0142]= 'b' ;
xchr[0143]= 'c' ;
xchr[0144]= 'd' ;
xchr[0145]= 'e' ;
xchr[0146]= 'f' ;
xchr[0147]= 'g' ;@/
xchr[0150]= 'h' ;
xchr[0151]= 'i' ;
xchr[0152]= 'j' ;
xchr[0153]= 'k' ;
xchr[0154]= 'l' ;
xchr[0155]= 'm' ;
xchr[0156]= 'n' ;
xchr[0157]= 'o' ;@/
xchr[0160]= 'p' ;
xchr[0161]= 'q' ;
xchr[0162]= 'r' ;
xchr[0163]= 's' ;
xchr[0164]= 't' ;
xchr[0165]= 'u' ;
xchr[0166]= 'v' ;
xchr[0167]= 'w' ;@/
xchr[0170]= 'x' ;
xchr[0171]= 'y' ;
xchr[0172]= 'z' ;
xchr[0173]= '{' ;
xchr[0174]= '|' ;
xchr[0175]= '}' ;
xchr[0176]= '~' ;
for (i=0177; i<=255; i++) xchr[i]= '?' ;

@ The following system-independent code makes the |xord| array contain a
suitable inverse to the information in |xchr|.

@<Set init...@>=
for (i=first_text_char; i<=last_text_char; i++) xord[chr(i)]=040;
for (i=' '; i<='~'; i++) xord[xchr[i]]=i;

@*Device-independent file format.
Before we get into the details of \.{DVItype}, we need to know exactly
what \.{DVI} files are. The form of such files was designed by David R.
@^Fuchs, David Raymond@>
Fuchs in 1979. Almost any reasonable typesetting device can be driven by
a program that takes \.{DVI} files as input, and dozens of such
\.{DVI}-to-whatever programs have been written. Thus, it is possible to
print the output of document compilers like \TeX\ on many different kinds
of equipment.

A \.{DVI} file is a stream of 8-bit bytes, which may be regarded as a
series of commands in a machine-like language. The first byte of each command
is the operation code, and this code is followed by zero or more bytes
that provide parameters to the command. The parameters themselves may consist
of several consecutive bytes; for example, the `|set_rule|' command has two
parameters, each of which is four bytes long. Parameters are usually
regarded as nonnegative integers; but four-byte-long parameters,
and shorter parameters that denote distances, can be
either positive or negative. Such parameters are given in two's complement
notation. For example, a two-byte-long distance parameter has a value between
$-2^{15}$ and $2^{15}-1$.
@.DVI {\rm files}@>

A \.{DVI} file consists of a ``preamble,'' followed by a sequence of one
or more ``pages,'' followed by a ``postamble.'' The preamble is simply a
|pre| command, with its parameters that define the dimensions used in the
file; this must come first.  Each ``page'' consists of a |bop| command,
followed by any number of other commands that tell where characters are to
be placed on a physical page, followed by an |eop| command. The pages
appear in the order that they were generated, not in any particular
numerical order. If we ignore |nop| commands and \\{fnt\_def} commands
(which are allowed between any two commands in the file), each |eop|
command is immediately followed by a |bop| command, or by a |post|
command; in the latter case, there are no more pages in the file, and the
remaining bytes form the postamble.  Further details about the postamble
will be explained later.

Some parameters in \.{DVI} commands are ``pointers.'' These are four-byte
quantities that give the location number of some other byte in the file;
the first byte is number~0, then comes number~1, and so on. For example,
one of the parameters of a |bop| command points to the previous |bop|;
this makes it feasible to read the pages in backwards order, in case the
results are being directed to a device that stacks its output face up.
Suppose the preamble of a \.{DVI} file occupies bytes 0 to 99. Now if the
first page occupies bytes 100 to 999, say, and if the second
page occupies bytes 1000 to 1999, then the |bop| that starts in byte 1000
points to 100 and the |bop| that starts in byte 2000 points to 1000. (The
very first |bop|, i.e., the one that starts in byte 100, has a pointer of $-1$.)

@ The \.{DVI} format is intended to be both compact and easily interpreted
by a machine. Compactness is achieved by making most of the information
implicit instead of explicit. When a \.{DVI}-reading program reads the
commands for a page, it keeps track of several quantities: (a)~The current
font |f| is an integer; this value is changed only
by \\{fnt} and \\{fnt\_num} commands. (b)~The current position on the page
is given by two numbers called the horizontal and vertical coordinates,
|h| and |v|. Both coordinates are zero at the upper left corner of the page;
moving to the right corresponds to increasing the horizontal coordinate, and
moving down corresponds to increasing the vertical coordinate. Thus, the
coordinates are essentially Cartesian, except that vertical directions are
flipped; the Cartesian version of |(h, v)| would be |(h,-v)|.  (c)~The
current spacing amounts are given by four numbers |w|, |x|, |y|, and |z|,
where |w| and~|x| are used for horizontal spacing and where |y| and~|z|
are used for vertical spacing. (d)~There is a stack containing
|(h, v, w, x, y, z)| values; the \.{DVI} commands |push| and |pop| are used to
change the current level of operation. Note that the current font~|f| is
not pushed and popped; the stack contains only information about
positioning.

The values of |h|, |v|, |w|, |x|, |y|, and |z| are signed integers having up
to 32 bits, including the sign. Since they represent physical distances,
there is a small unit of measurement such that increasing |h| by~1 means
moving a certain tiny distance to the right. The actual unit of
measurement is variable, as explained below.

@ Here is a list of all the commands that may appear in a \.{DVI} file. Each
command is specified by its symbolic name (e.g., |bop|), its opcode byte
(e.g., 139), and its parameters (if any). The parameters are followed
by a bracketed number telling how many bytes they occupy; for example,
`|p[4]|' means that parameter |p| is four bytes long.

\yskip\hang|set_char_0| 0. Typeset character number~0 from font~|f|
such that the reference point of the character is at |(h, v)|. Then
increase |h| by the width of that character. Note that a character may
have zero or negative width, so one cannot be sure that |h| will advance
after this command; but |h| usually does increase.

\yskip\hang|set_char_1| through |set_char_127| (opcodes 1 to 127).
Do the operations of |set_char_0|; but use the character whose number
matches the opcode, instead of character~0.

\yskip\hang|set1| 128 |c[1]|. Same as |set_char_0|, except that character
number~|c| is typeset. \TeX82 uses this command for characters in the
range |128 <= c < 256|.

\yskip\hang|set2| 129 |c[2]|. Same as |set1|, except that |c|~is two
bytes long, so it is in the range |0 <= c < 65536|. \TeX82 never uses this
command, which is intended for processors that deal with oriental languages;
but \.{DVItype} will allow character codes greater than 255, assuming that
they all have the same width as the character whose code is $c \bmod 256$.
@^oriental characters@>@^Chinese characters@>@^Japanese characters@>

\yskip\hang|set3| 130 |c[3]|. Same as |set1|, except that |c|~is three
bytes long, so it can be as large as $2^{24}-1$.

\yskip\hang|set4| 131 |c[4]|. Same as |set1|, except that |c|~is four
bytes long, possibly even negative. Imagine that.

\yskip\hang|set_rule| 132 |a[4]| |b[4]|. Typeset a solid black rectangle
of height |a| and width |b|, with its bottom left corner at |(h, v)|. Then
set |h=h+b|. If either |a <= 0| or |b <= 0|, nothing should be typeset. Note
that if |b < 0|, the value of |h| will decrease even though nothing else happens.
Programs that typeset from \.{DVI} files should be careful to make the rules
line up carefully with digitized characters, as explained in connection with
the |rule_pixels| subroutine below.

\yskip\hang|put1| 133 |c[1]|. Typeset character number~|c| from font~|f|
such that the reference point of the character is at |(h, v)|. (The `put'
commands are exactly like the `set' commands, except that they simply put out a
character or a rule without moving the reference point afterwards.)

\yskip\hang|put2| 134 |c[2]|. Same as |set2|, except that |h| is not changed.

\yskip\hang|put3| 135 |c[3]|. Same as |set3|, except that |h| is not changed.

\yskip\hang|put4| 136 |c[4]|. Same as |set4|, except that |h| is not changed.

\yskip\hang|put_rule| 137 |a[4]| |b[4]|. Same as |set_rule|, except that
|h| is not changed.

\yskip\hang|nop| 138. No operation, do nothing. Any number of |nop|'s
may occur between \.{DVI} commands, but a |nop| cannot be inserted between
a command and its parameters or between two parameters.

\yskip\hang|bop| 139 $c_0[4]$ $c_1[4]$ $\ldots$ $c_9[4]$ $p[4]$. Beginning
of a page: Set |(h, v, w, x, y, z)=(0, 0, 0, 0, 0, 0)| and set the stack empty. Set
the current font |f| to an undefined value.  The ten $c_i$ parameters can
be used to identify pages, if a user wants to print only part of a \.{DVI}
file; \TeX82 gives them the values of \.{\\count0} $\ldots$ \.{\\count9}
at the time \.{\\shipout} was invoked for this page.  The parameter |p|
points to the previous |bop| command in the file, where the first |bop|
has $p=-1$.

\yskip\hang|eop| 140.  End of page: Print what you have read since the
previous |bop|. At this point the stack should be empty. (The \.{DVI}-reading
programs that drive most output devices will have kept a buffer of the
material that appears on the page that has just ended. This material is
largely, but not entirely, in order by |v| coordinate and (for fixed |v|) by
|h|~coordinate; so it usually needs to be sorted into some order that is
appropriate for the device in question. \.{DVItype} does not do such sorting.)

\yskip\hang|push| 141. Push the current values of |(h, v, w, x, y, z)| onto the
top of the stack; do not change any of these values. Note that |f| is
not pushed.

\yskip\hang|pop| 142. Pop the top six values off of the stack and assign
them to |(h, v, w, x, y, z)|. The number of pops should never exceed the number
of pushes, since it would be highly embarrassing if the stack were empty
at the time of a |pop| command.

\yskip\hang|right1| 143 |b[1]|. Set |h=h+b|, i.e., move right |b| units.
The parameter is a signed number in two's complement notation, |-128 <= b < 128|;
if |b < 0|, the reference point actually moves left.

\yskip\hang|right2| 144 |b[2]|. Same as |right1|, except that |b| is a
two-byte quantity in the range |-32768 <= b < 32768|.

\yskip\hang|right3| 145 |b[3]|. Same as |right1|, except that |b| is a
three-byte quantity in the range |@t$-2^{23}$@> <= b < @t$2^{23}$@>|.

\yskip\hang|right4| 146 |b[4]|. Same as |right1|, except that |b| is a
four-byte quantity in the range |@t$-2^{31}$@> <= b < @t$2^{31}$@>|.

\yskip\hang|w0| 147. Set |h=h+w|; i.e., move right |w| units. With luck,
this parameterless command will usually suffice, because the same kind of motion
will occur several times in succession; the following commands explain how
|w| gets particular values.

\yskip\hang|w1| 148 |b[1]|. Set |w=b| and |h=h+b|. The value of |b| is a
signed quantity in two's complement notation, |-128 <= b < 128|. This command
changes the current |w|~spacing and moves right by |b|.

\yskip\hang|w2| 149 |b[2]|. Same as |w1|, but |b| is a two-byte-long
parameter, |-32768 <= b < 32768|.

\yskip\hang|w3| 150 |b[3]|. Same as |w1|, but |b| is a three-byte-long
parameter, |@t$-2^{23}$@> <= b < @t$2^{23}$@>|.

\yskip\hang|w4| 151 |b[4]|. Same as |w1|, but |b| is a four-byte-long
parameter, |@t$-2^{31}$@> <= b < @t$2^{31}$@>|.

\yskip\hang|x0| 152. Set |h=h+x|; i.e., move right |x| units. The `|x|'
commands are like the `|w|' commands except that they involve |x| instead
of |w|.

\yskip\hang|x1| 153 |b[1]|. Set |x=b| and |h=h+b|. The value of |b| is a
signed quantity in two's complement notation, |-128 <= b < 128|. This command
changes the current |x|~spacing and moves right by |b|.

\yskip\hang|x2| 154 |b[2]|. Same as |x1|, but |b| is a two-byte-long
parameter, |-32768 <= b < 32768|.

\yskip\hang|x3| 155 |b[3]|. Same as |x1|, but |b| is a three-byte-long
parameter, |@t$-2^{23}$@> <= b < @t$2^{23}$@>|.

\yskip\hang|x4| 156 |b[4]|. Same as |x1|, but |b| is a four-byte-long
parameter, |@t$-2^{31}$@> <= b < @t$2^{31}$@>|.

\yskip\hang|down1| 157 |a[1]|. Set |v=v+a|, i.e., move down |a| units.
The parameter is a signed number in two's complement notation, |-128 <= a < 128|;
if |a < 0|, the reference point actually moves up.

\yskip\hang|down2| 158 |a[2]|. Same as |down1|, except that |a| is a
two-byte quantity in the range |-32768 <= a < 32768|.

\yskip\hang|down3| 159 |a[3]|. Same as |down1|, except that |a| is a
three-byte quantity in the range |@t$-2^{23}$@> <= a < @t$2^{23}$@>|.

\yskip\hang|down4| 160 |a[4]|. Same as |down1|, except that |a| is a
four-byte quantity in the range |@t$-2^{31}$@> <= a < @t$2^{31}$@>|.

\yskip\hang|y0| 161. Set |v=v+y|; i.e., move down |y| units. With luck,
this parameterless command will usually suffice, because the same kind of motion
will occur several times in succession; the following commands explain how
|y| gets particular values.

\yskip\hang|y1| 162 |a[1]|. Set |y=a| and |v=v+a|. The value of |a| is a
signed quantity in two's complement notation, |-128 <= a < 128|. This command
changes the current |y|~spacing and moves down by |a|.

\yskip\hang|y2| 163 |a[2]|. Same as |y1|, but |a| is a two-byte-long
parameter, |-32768 <= a < 32768|.

\yskip\hang|y3| 164 |a[3]|. Same as |y1|, but |a| is a three-byte-long
parameter, |@t$-2^{23}$@> <= a < @t$2^{23}$@>|.

\yskip\hang|y4| 165 |a[4]|. Same as |y1|, but |a| is a four-byte-long
parameter, |@t$-2^{31}$@> <= a < @t$2^{31}$@>|.

\yskip\hang|z0| 166. Set |v=v+z|; i.e., move down |z| units. The `|z|' commands
are like the `|y|' commands except that they involve |z| instead of |y|.

\yskip\hang|z1| 167 |a[1]|. Set |z=a| and |v=v+a|. The value of |a| is a
signed quantity in two's complement notation, |-128 <= a < 128|. This command
changes the current |z|~spacing and moves down by |a|.

\yskip\hang|z2| 168 |a[2]|. Same as |z1|, but |a| is a two-byte-long
parameter, |-32768 <= a < 32768|.

\yskip\hang|z3| 169 |a[3]|. Same as |z1|, but |a| is a three-byte-long
parameter, |@t$-2^{23}$@> <= a < @t$2^{23}$@>|.

\yskip\hang|z4| 170 |a[4]|. Same as |z1|, but |a| is a four-byte-long
parameter, |@t$-2^{31}$@> <= a < @t$2^{31}$@>|.

\yskip\hang|fnt_num_0| 171. Set |f=0|. Font 0 must previously have been
defined by a \\{fnt\_def} instruction, as explained below.

\yskip\hang|fnt_num_1| through |fnt_num_63| (opcodes 172 to 234). Set
|f=1|, \dots, |f=63|, respectively.

\yskip\hang|fnt1| 235 |k[1]|. Set |f=k|. \TeX82 uses this command for font
numbers in the range |64 <= k < 256|.

\yskip\hang|fnt2| 236 |k[2]|. Same as |fnt1|, except that |k|~is two
bytes long, so it is in the range |0 <= k < 65536|. \TeX82 never generates this
command, but large font numbers may prove useful for specifications of
color or texture, or they may be used for special fonts that have fixed
numbers in some external coding scheme.

\yskip\hang|fnt3| 237 |k[3]|. Same as |fnt1|, except that |k|~is three
bytes long, so it can be as large as $2^{24}-1$.

\yskip\hang|fnt4| 238 |k[4]|. Same as |fnt1|, except that |k|~is four
bytes long; this is for the really big font numbers (and for the negative ones).

\yskip\hang|xxx1| 239 |k[1]| |x[k]|. This command is undefined in
general; it functions as a $(k+2)$-byte |nop| unless special \.{DVI}-reading
programs are being used. \TeX82 generates |xxx1| when a short enough
\.{\\special} appears, setting |k| to the number of bytes being sent. It
is recommended that |x| be a string having the form of a keyword followed
by possible parameters relevant to that keyword.

\yskip\hang|xxx2| 240 |k[2]| |x[k]|. Like |xxx1|, but |0 <= k < 65536|.

\yskip\hang|xxx3| 241 |k[3]| |x[k]|. Like |xxx1|, but |0 <= k < @t$2^{24}$@>|.

\yskip\hang|xxx4| 242 |k[4]| |x[k]|. Like |xxx1|, but |k| can be ridiculously
large. \TeX82 uses |xxx4| when |xxx1| would be incorrect.

\yskip\hang|fnt_def1| 243 |k[1]| |c[4]| |s[4]| |d[4]| |a[1]| |l[1]| |n[a+l]|.
Define font |k|, where |0 <= k < 256|; font definitions will be explained shortly.

\yskip\hang|fnt_def2| 244 |k[2]| |c[4]| |s[4]| |d[4]| |a[1]| |l[1]| |n[a+l]|.
Define font |k|, where |0 <= k < 65536|.

\yskip\hang|fnt_def3| 245 |k[3]| |c[4]| |s[4]| |d[4]| |a[1]| |l[1]| |n[a+l]|.
Define font |k|, where |0 <= k < @t$2^{24}$@>|.

\yskip\hang|fnt_def4| 246 |k[4]| |c[4]| |s[4]| |d[4]| |a[1]| |l[1]| |n[a+l]|.
Define font |k|, where |@t$-2^{31}$@> <= k < @t$2^{31}$@>|.

\yskip\hang|pre| 247 |i[1]| |num[4]| |den[4]| |mag[4]| |k[1]| |x[k]|.
Beginning of the preamble; this must come at the very beginning of the
file. Parameters |i|, |num|, |den|, |mag|, |k|, and |x| are explained below.

\yskip\hang|post| 248. Beginning of the postamble, see below.

\yskip\hang|post_post| 249. Ending of the postamble, see below.

\yskip\noindent Commands 250--255 are undefined at the present time.

@ @d set_char_0	0 /*typeset character 0 and move right*/ 
@d set1	128 /*typeset a character and move right*/ 
@d set_rule	132 /*typeset a rule and move right*/ 
@d put1	133 /*typeset a character*/ 
@d put_rule	137 /*typeset a rule*/ 
@d nop	138 /*no operation*/ 
@d bop	139 /*beginning of page*/ 
@d eop	140 /*ending of page*/ 
@d push	141 /*save the current positions*/ 
@d pop	142 /*restore previous positions*/ 
@d right1	143 /*move right*/ 
@d w0	147 /*move right by |w|*/ 
@d w1	148 /*move right and set |w|*/ 
@d x0	152 /*move right by |x|*/ 
@d x1	153 /*move right and set |x|*/ 
@d down1	157 /*move down*/ 
@d y0	161 /*move down by |y|*/ 
@d y1	162 /*move down and set |y|*/ 
@d z0	166 /*move down by |z|*/ 
@d z1	167 /*move down and set |z|*/ 
@d fnt_num_0	171 /*set current font to 0*/ 
@d fnt1	235 /*set current font*/ 
@d xxx1	239 /*extension to \.{DVI} primitives*/ 
@d xxx4	242 /*potentially long extension to \.{DVI} primitives*/ 
@d fnt_def1	243 /*define the meaning of a font number*/ 
@d pre	247 /*preamble*/ 
@d post	248 /*postamble beginning*/ 
@d post_post	249 /*postamble ending*/ 
@d undefined_commands	case 250: case 251: case 252: case 253: case 254: case 255

@ The preamble contains basic information about the file as a whole. As
stated above, there are six parameters:
$$\hbox{|@!i[1]| |@!num[4]| |@!den[4]| |@!mag[4]| |@!k[1]| |@!x[k]|.}$$
The |i| byte identifies \.{DVI} format; currently this byte is always set
to~2. (The value |i==3| is currently used for an extended format that
allows a mixture of right-to-left and left-to-right typesetting.
Some day we will set |i==4|, when \.{DVI} format makes another
incompatible change---perhaps in the year 2048.)

The next two parameters, |num| and |den|, are positive integers that define
the units of measurement; they are the numerator and denominator of a
fraction by which all dimensions in the \.{DVI} file could be multiplied
in order to get lengths in units of $10^{-7}$ meters. (For example, there are
exactly 7227 \TeX\ points in 254 centimeters, and \TeX82 works with scaled
points where there are $2^{16}$ sp in a point, so \TeX82 sets |num==25400000|
and $|den|=7227\cdot2^{16}=473628672$.)
@^sp@>

The |mag| parameter is what \TeX82 calls \.{\\mag}, i.e., 1000 times the
desired magnification. The actual fraction by which dimensions are
multiplied is therefore $mn/1000d$. Note that if a \TeX\ source document
does not call for any `\.{true}' dimensions, and if you change it only by
specifying a different \.{\\mag} setting, the \.{DVI} file that \TeX\
creates will be completely unchanged except for the value of |mag| in the
preamble and postamble. (Fancy \.{DVI}-reading programs allow users to
override the |mag|~setting when a \.{DVI} file is being printed.)

Finally, |k| and |x| allow the \.{DVI} writer to include a comment, which is not
interpreted further. The length of comment |x| is |k|, where |0 <= k < 256|.

@d id_byte	2 /*identifies the kind of \.{DVI} files described here*/ 

@ Font definitions for a given font number |k| contain further parameters
$$\hbox{|c[4]| |s[4]| |d[4]| |a[1]| |l[1]| |n[a+l]|.}$$
The four-byte value |c| is the check sum that \TeX\ (or whatever program
generated the \.{DVI} file) found in the \.{TFM} file for this font;
|c| should match the check sum of the font found by programs that read
this \.{DVI} file.
@^check sum@>

Parameter |s| contains a fixed-point scale factor that is applied to the
character widths in font |k|; font dimensions in \.{TFM} files and other
font files are relative to this quantity, which is always positive and
less than $2^{27}$. It is given in the same units as the other dimensions
of the \.{DVI} file.  Parameter |d| is similar to |s|; it is the ``design
size,'' and (like~|s|) it is given in \.{DVI} units. Thus, font |k| is to be
used at $|mag|\cdot s/1000d$ times its normal size.

The remaining part of a font definition gives the external name of the font,
which is an ASCII string of length |a+l|. The number |a| is the length
of the ``area'' or directory, and |l| is the length of the font name itself;
the standard local system font area is supposed to be used when |a==0|.
The |n| field contains the area in its first |a| bytes.

Font definitions must appear before the first use of a particular font number.
Once font |k| is defined, it must not be defined again; however, we
shall see below that font definitions appear in the postamble as well as
in the pages, so in this sense each font number is defined exactly twice,
if at all. Like |nop| commands, font definitions can
appear before the first |bop|, or between an |eop| and a |bop|.

@ The last page in a \.{DVI} file is followed by `|post|'; this command
introduces the postamble, which summarizes important facts that \TeX\ has
accumulated about the file, making it possible to print subsets of the data
with reasonable efficiency. The postamble has the form
$$\vbox{\halign{\hbox{#\hfil}\cr
  |post| |p[4]| |num[4]| |den[4]| |mag[4]| |l[4]| |u[4]| |s[2]| |t[2]|\cr
  $\langle\,$font definitions$\,\rangle$\cr
  |post_post| |q[4]| |i[1]| 223's$[{\G}4]$\cr}}$$
Here |p| is a pointer to the final |bop| in the file. The next three
parameters, |num|, |den|, and |mag|, are duplicates of the quantities that
appeared in the preamble.

Parameters |l| and |u| give respectively the height-plus-depth of the tallest
page and the width of the widest page, in the same units as other dimensions
of the file. These numbers might be used by a \.{DVI}-reading program to
position individual ``pages'' on large sheets of film or paper; however,
the standard convention for output on normal size paper is to position each
page so that the upper left-hand corner is exactly one inch from the left
and the top. Experience has shown that it is unwise to design \.{DVI}-to-printer
software that attempts cleverly to center the output; a fixed position of
the upper left corner is easiest for users to understand and to work with.
Therefore |l| and~|u| are often ignored.

Parameter |s| is the maximum stack depth (i.e., the largest excess of
|push| commands over |pop| commands) needed to process this file. Then
comes |t|, the total number of pages (|bop| commands) present.

The postamble continues with font definitions, which are any number of
\\{fnt\_def} commands as described above, possibly interspersed with |nop|
commands. Each font number that is used in the \.{DVI} file must be defined
exactly twice: Once before it is first selected by a \\{fnt} command, and once
in the postamble.

@ The last part of the postamble, following the |post_post| byte that
signifies the end of the font definitions, contains |q|, a pointer to the
|post| command that started the postamble.  An identification byte, |i|,
comes next; this currently equals~2, as in the preamble.

The |i| byte is followed by four or more bytes that are all equal to
the decimal number 223 (i.e., 0337 in octal). \TeX\ puts out four to seven of
these trailing bytes, until the total length of the file is a multiple of
four bytes, since this works out best on machines that pack four bytes per
word; but any number of 223's is allowed, as long as there are at least four
of them. In effect, 223 is a sort of signature that is added at the very end.
@^Fuchs, David Raymond@>

This curious way to finish off a \.{DVI} file makes it feasible for
\.{DVI}-reading programs to find the postamble first, on most computers,
even though \TeX\ wants to write the postamble last. Most operating
systems permit random access to individual words or bytes of a file, so
the \.{DVI} reader can start at the end and skip backwards over the 223's
until finding the identification byte. Then it can back up four bytes, read
|q|, and move to byte |q| of the file. This byte should, of course,
contain the value 248 (|post|); now the postamble can be read, so the
\.{DVI} reader discovers all the information needed for typesetting the
pages. Note that it is also possible to skip through the \.{DVI} file at
reasonably high speed to locate a particular page, if that proves
desirable. This saves a lot of time, since \.{DVI} files used in production
jobs tend to be large.

Unfortunately, however, standard \PASCAL\ does not include the ability to
@^system dependencies@>
access a random position in a file, or even to determine the length of a file.
Almost all systems nowadays provide the necessary capabilities, so \.{DVI}
format has been designed to work most efficiently with modern operating systems.
As noted above, \.{DVItype} will limit itself to the restrictions of standard
\PASCAL\ if |random_reading| is defined to be |false|.

@*Input from binary files.
We have seen that a \.{DVI} file is a sequence of 8-bit bytes. The bytes
appear physically in what is called a `|File 0 dotdot 255|'
in \PASCAL\ lingo.

Packing is system dependent, and many \PASCAL\ systems fail to implement
such files in a sensible way (at least, from the viewpoint of producing
good production software).  For example, some systems treat all
byte-oriented files as text, looking for end-of-line marks and such
things. Therefore some system-dependent code is often needed to deal with
binary files, even though most of the program in this section of
\.{DVItype} is written in standard \PASCAL.
@^system dependencies@>

One common way to solve the problem is to consider files of |int|
numbers, and to convert an integer in the range $-2^{31}\L x<2^{31}$ to
a sequence of four bytes $(a,b,c,d)$ using the following code, which
avoids the controversial integer division of negative numbers:
$$\vbox{\halign{#\hfil\cr
|if (x >= 0) a=x/0100000000|\cr
|else{@+x=(x+010000000000)+010000000000;a=x/0100000000+128;|\cr
\quad|} |\cr
|x=x%0100000000;|\cr
|b=x/0200000;x=x%0200000;|\cr
|c=x/0400;d=x%0400;|\cr}}$$
The four bytes are then kept in a buffer and output one by one. (On 36-bit
computers, an additional division by 16 is necessary at the beginning.
Another way to separate an integer into four bytes is to use/abuse
\PASCAL's variant records, storing an integer and retrieving bytes that are
packed in the same place; {\sl caveat implementor!\/}) It is also desirable
in some cases to read a hundred or so integers at a time, maintaining a
larger buffer.

We shall stick to simple \PASCAL\ in this program, for reasons of clarity,
even if such simplicity is sometimes unrealistic.

@<Types...@>=
typedef uint8_t eight_bits; /*unsigned one-byte quantity*/ 
typedef struct {@+FILE *f;@+eight_bits@,d;@+} byte_file; /*files that contain binary data*/ 

@ The program deals with two binary file variables: |dvi_file| is the main
input file that we are translating into symbolic form, and |tfm_file| is
the current font metric file from which character-width information is
being read.

@<Glob...@>=
byte_file @!dvi_file; /*the stuff we are \.{DVI}typing*/ 
byte_file @!tfm_file; /*a font metric file*/ 

@ To prepare these files for input, we |reset| them. An extension of
\PASCAL\ is needed in the case of |tfm_file|, since we want to associate
it with external files whose names are specified dynamically (i.e., not
known at compile time). The following code assumes that `|reset(f, s)|'
does this, when |f| is a file variable and |s| is a string variable that
specifies the file name. If |eof(f)| is true immediately after
|reset(f, s)| has acted, we assume that no file named |s| is accessible.
@^system dependencies@>

@p void open_dvi_file(void) /*prepares to read packed bytes in |dvi_file|*/ 
{@+get(dvi_file);
cur_loc=0;
} 
@#
void open_tfm_file(void) /*prepares to read packed bytes in |tfm_file|*/ 
{@+reset(tfm_file, cur_name);
} 

@ If you looked carefully at the preceding code, you probably asked,
``What are |cur_loc| and |cur_name|?'' Good question. They're global
variables: |cur_loc| is the number of the byte about to be read next from
|dvi_file|, and |cur_name| is a string variable that will be set to the
current font metric file name before |open_tfm_file| is called.

@<Glob...@>=
int @!cur_loc; /*where we are about to look, in |dvi_file|*/ 
uint8_t @!cur_name0[name_length+1], *const @!cur_name = @!cur_name0-1; /*external name,
  with no lower case letters*/ 

@ It turns out to be convenient to read four bytes at a time, when we are
inputting from \.{TFM} files. The input goes into global variables
|b0|, |b1|, |b2|, and |b3|, with |b0| getting the first byte and |b3|
the fourth.

@<Glob...@>=
eight_bits @!b0, @!b1, @!b2, @!b3; /*four bytes input at once*/ 

@ The |read_tfm_word| procedure sets |b0| through |b3| to the next
four bytes in the current \.{TFM} file.
@^system dependencies@>

@p void read_tfm_word(void)
{@+read(tfm_file, b0);read(tfm_file, b1);
read(tfm_file, b2);read(tfm_file, b3);
} 

@ We shall use another set of simple functions to read the next byte or
bytes from |dvi_file|. There are seven possibilities, each of which is
treated as a separate function in order to minimize the overhead for
subroutine calls.
@^system dependencies@>

@p int get_byte(void) /*returns the next byte, unsigned*/ 
{@+eight_bits b;
if (eof(dvi_file)) return 0;
else{@+read(dvi_file, b);incr(cur_loc);return b;
  } 
} 
@#
int signed_byte(void) /*returns the next byte, signed*/ 
{@+eight_bits b;
read(dvi_file, b);incr(cur_loc);
if (b < 128) return b;@+else return b-256;
} 
@#
int get_two_bytes(void) /*returns the next two bytes, unsigned*/ 
{@+eight_bits a, @!b;
read(dvi_file, a);read(dvi_file, b);
cur_loc=cur_loc+2;
return a*256+b;
} 
@#
int signed_pair(void) /*returns the next two bytes, signed*/ 
{@+eight_bits a, @!b;
read(dvi_file, a);read(dvi_file, b);
cur_loc=cur_loc+2;
if (a < 128) return a*256+b;
else return(a-256)*256+b;
} 
@#
int get_three_bytes(void) /*returns the next three bytes, unsigned*/ 
{@+eight_bits a, @!b, @!c;
read(dvi_file, a);read(dvi_file, b);read(dvi_file, c);
cur_loc=cur_loc+3;
return(a*256+b)*256+c;
} 
@#
int signed_trio(void) /*returns the next three bytes, signed*/ 
{@+eight_bits a, @!b, @!c;
read(dvi_file, a);read(dvi_file, b);read(dvi_file, c);
cur_loc=cur_loc+3;
if (a < 128) return(a*256+b)*256+c;
else return((a-256)*256+b)*256+c;
} 
@#
int signed_quad(void) /*returns the next four bytes, signed*/ 
{@+eight_bits a, @!b, @!c, @!d;
read(dvi_file, a);read(dvi_file, b);read(dvi_file, c);read(dvi_file, d);
cur_loc=cur_loc+4;
if (a < 128) return((a*256+b)*256+c)*256+d;
else return(((a-256)*256+b)*256+c)*256+d;
} 

@ Finally we come to the routines that are used only if |random_reading| is
|true|. The driver program below needs two such routines: |dvi_length| should
compute the total number of bytes in |dvi_file|, possibly also
causing |eof(dvi_file)| to be true; and |move_to_byte(n)|
should position |dvi_file| so that the next |get_byte| will read byte |n|,
starting with |n==0| for the first byte in the file.
@^system dependencies@>

Such routines are, of course, highly system dependent. They are implemented
here in terms of two assumed system routines called |set_pos| and |cur_pos|.
The call |set_pos(f, n)| moves to item |n| in file |f|, unless |n| is
negative or larger than the total number of items in |f|; in the latter
case, |set_pos(f, n)| moves to the end of file |f|.
The call |cur_pos(f)| gives the total number of items in |f|, if
|eof(f)| is true; we use |cur_pos| only in such a situation.

@p int dvi_length(void)
{@+fseek(dvi_file.f,0,SEEK_END);return ftell(dvi_file.f);
} 
@#
void move_to_byte(int n)
{@+set_pos(dvi_file, n);cur_loc=n;
} 

@*Reading the font information.
\.{DVI} file format does not include information about character widths, since
that would tend to make the files a lot longer. But a program that reads
a \.{DVI} file is supposed to know the widths of the characters that appear
in \\{set\_char} commands. Therefore \.{DVItype} looks at the font metric
(\.{TFM}) files for the fonts that are involved.
@.TFM {\rm files}@>

The character-width data appears also in other files (e.g., in \.{GF} files
that specify bit patterns for digitized characters);
thus, it is usually possible for \.{DVI} reading programs to get by with
accessing only one file per font. \.{DVItype} has a comparatively easy
task in this regard, since it needs only a few words of information from
each font; other \.{DVI}-to-printer programs may have to go to some pains to
deal with complications that arise when a large number of large font files
all need to be accessed simultaneously.

@ For purposes of this program, we need to know only two things about a
given character |c| in a given font |f|: (1)~Is |c| a legal character
in~|f|? (2)~If so, what is the width of |c|? We also need to know the
symbolic name of each font, so it can be printed out, and we need to know
the approximate size of inter-word spaces in each font.

The answers to these questions appear implicitly in the following data
structures. The current number of known fonts is |nf|. Each known font has
an internal number |f|, where |0 <= f < nf|; the external number of this font,
i.e., its font identification number in the \.{DVI} file, is
|font_num[f]|, and the external name of this font is the string that
occupies positions |font_name[f]| through |font_name[f+1]-1| of the array
|names|. The latter array consists of |ASCII_code| characters, and
|font_name[nf]| is its first unoccupied position.  A horizontal motion
in the range |-4*font_space[f] < h < font_space[f]|
will be treated as a `kern' that is not
indicated in the printouts that \.{DVItype} produces between brackets. The
legal characters run from |font_bc[f]| to |font_ec[f]|, inclusive; more
precisely, a given character |c| is valid in font |f| if and only if
|font_bc[f] <= c <= font_ec[f]| and |char_width(f)(c)!=invalid_width|.
Finally, |char_width(f)(c)==width[width_base[f]+c]|, and |width_ptr| is the
first unused position of the |width| array.

@d char_width_end(X)	X]
@d char_width(X)	width[width_base[X]+char_width_end
@d invalid_width	017777777777
@d invalid_font	max_fonts

@<Glob...@>=
int @!font_num[max_fonts+1]; /*external font numbers*/ 
uint16_t @!font_name[max_fonts+1]; /*starting positions
  of external font names*/ 
ASCII_code @!names0[name_size], *const @!names = @!names0-1; /*characters of names*/ 
int @!font_check_sum[max_fonts+1]; /*check sums*/ 
int @!font_scaled_size[max_fonts+1]; /*scale factors*/ 
int @!font_design_size[max_fonts+1]; /*design sizes*/ 
int @!font_space[max_fonts+1]; /*boundary between ``small''
  and ``large'' spaces*/ 
int @!font_bc[max_fonts+1]; /*beginning characters in fonts*/ 
int @!font_ec[max_fonts+1]; /*ending characters in fonts*/ 
int @!width_base[max_fonts+1]; /*index into |width| table*/ 
int @!width[max_widths+1]; /*character widths, in \.{DVI} units*/ 
uint8_t @!nf; /*the number of known fonts*/ 
uint16_t @!width_ptr; /*the number of known character widths*/ 

@ @<Set init...@>=
nf=0;width_ptr=0;font_name[0]=1;@/
font_space[invalid_font]=0; /*for |out_space| and |out_vmove|*/ 
font_bc[invalid_font]=1;font_ec[invalid_font]=0;

@ It is, of course, a simple matter to print the name of a given font.

@p void print_font(int @!f) /*|f| is an internal font number*/ 
{@+int k; /*index into |names|*/ 
if (f==invalid_font) print("UNDEFINED!");
@.UNDEFINED@>
else{@+for (k=font_name[f]; k<=font_name[f+1]-1; k++) 
    print("%c",xchr[names[k]]);
  } 
} 

@ An auxiliary array |in_width| is used to hold the widths as they are
input. The global variables |tfm_check_sum| and |tfm_design_size| are
set to the check sum and design size that
appear in the current \.{TFM} file.

@<Glob...@>=
int @!in_width[256]; /*\.{TFM} width data in \.{DVI} units*/ 
int @!tfm_check_sum; /*check sum found in |tfm_file|*/ 
int @!tfm_design_size; /*design size found in |tfm_file|, in \.{DVI} units*/ 
double @!tfm_conv; /*\.{DVI} units per absolute \.{TFM} unit*/ 

@ Here is a procedure that absorbs the necessary information from a
\.{TFM} file, assuming that the file has just been successfully reset
so that we are ready to read its first byte. (A complete description of
\.{TFM} file format appears in the documentation of \.{TFtoPL} and will
not be repeated here.) The procedure does not check the \.{TFM} file
for validity, nor does it give explicit information about what is
wrong with a \.{TFM} file that proves to be invalid; \.{DVI}-reading
programs need not do this, since \.{TFM} files are almost always valid,
and since the \.{TFtoPL} utility program has been specifically designed
to diagnose \.{TFM} errors. The procedure simply returns |false| if it
detects anything amiss in the \.{TFM} data.

There is a parameter, |z|, which represents the scaling factor being
used to compute the font dimensions; it must be in the range $0<z<2^{27}$.

@p bool in_TFM(int @!z) /*input \.{TFM} data or return |false|*/ 
{@+ /*go here when the format is bad*/ 
   /*go here when the information cannot be loaded*/ 
   /*go here to exit*/ 
int k; /*index for loops*/ 
int @!lh; /*length of the header data, in four-byte words*/ 
int @!nw; /*number of words in the width table*/ 
uint16_t @!wp; /*new value of |width_ptr| after successful input*/ 
int @!alpha, @!beta; /*quantities used in the scaling computation*/ 
@<Read past the header data; |goto 9997| if there is a problem@>;
@<Store character-width indices at the end of the |width| table@>;
@<Read and convert the width values, setting up the |in_width| table@>;
@<Move the widths from |in_width| to |width|, and append |pixel_width| values@>;
width_ptr=wp;return true;
label9997: print_ln("---not loaded, TFM file is bad");
@.TFM file is bad@>
return false;
}

@ @<Read past the header...@>=
read_tfm_word();lh=b2*256+b3;
read_tfm_word();font_bc[nf]=b0*256+b1;font_ec[nf]=b2*256+b3;
if (font_ec[nf] < font_bc[nf]) font_bc[nf]=font_ec[nf]+1;
if (width_ptr+font_ec[nf]-font_bc[nf]+1 > max_widths) 
  {@+print_ln("---not loaded, DVItype needs larger width table");
@.DVItype needs larger...@>
    return false;
  } 
wp=width_ptr+font_ec[nf]-font_bc[nf]+1;
read_tfm_word();nw=b0*256+b1;
if ((nw==0)||(nw > 256)) goto label9997;
for (k=1; k<=3+lh; k++) 
  {@+if (eof(tfm_file)) goto label9997;
  read_tfm_word();
  if (k==4) 
    if (b0 < 128) tfm_check_sum=((b0*256+b1)*256+b2)*256+b3;
    else tfm_check_sum=(((b0-256)*256+b1)*256+b2)*256+b3;
  else if (k==5) 
    if (b0 < 128) 
      tfm_design_size=round(tfm_conv*(((b0*256+b1)*256+b2)*256+b3));
    else goto label9997;
  } 

@ @<Store character-width indices...@>=
if (wp > 0) for (k=width_ptr; k<=wp-1; k++) 
  {@+read_tfm_word();
  if (b0 > nw) goto label9997;
  width[k]=b0;
  } 

@ The most important part of |in_TFM| is the width computation, which
involves multiplying the relative widths in the \.{TFM} file by the
scaling factor in the \.{DVI} file. This fixed-point multiplication
must be done with precisely the same accuracy by all \.{DVI}-reading programs,
in order to validate the assumptions made by \.{DVI}-writing programs
like \TeX82.

Let us therefore summarize what needs to be done. Each width in a \.{TFM}
file appears as a four-byte quantity called a |fix_word|.  A |fix_word|
whose respective bytes are $(a,b,c,d)$ represents the number
$$x=\left\{\vcenter{\halign{$#$,\hfil\qquad&if $#$\hfil\cr
b\cdot2^{-4}+c\cdot2^{-12}+d\cdot2^{-20}&a=0;\cr
-16+b\cdot2^{-4}+c\cdot2^{-12}+d\cdot2^{-20}&a=255.\cr}}\right.$$
(No other choices of $a$ are allowed, since the magnitude of a \.{TFM}
dimension must be less than 16.)  We want to multiply this quantity by the
integer~|z|, which is known to be less than $2^{27}$.
If $|z|<2^{23}$, the individual multiplications $b\cdot z$, $c\cdot z$,
$d\cdot z$ cannot overflow; otherwise we will divide |z| by 2, 4, 8, or
16, to obtain a multiplier less than $2^{23}$, and we can compensate for
this later. If |z| has thereby been replaced by $|z|^\prime=|z|/2^e$, let
$\beta=2^{4-e}$; we shall compute
$$\lfloor(b+c\cdot2^{-8}+d\cdot2^{-16})\,z^\prime/\beta\rfloor$$ if $a=0$,
or the same quantity minus $\alpha=2^{4+e}z^\prime$ if $a=255$.
This calculation must be
done exactly, for the reasons stated above; the following program does the
job in a system-independent way, assuming that arithmetic is exact on
numbers less than $2^{31}$ in magnitude.

@<Read and convert the width values...@>=
@<Replace |z| by $|z|^\prime$ and compute $\alpha,\beta$@>;
for (k=0; k<=nw-1; k++) 
  {@+read_tfm_word();
  in_width[k]=(((((b3*z)/0400)+(b2*z))/0400)+(b1*z))/beta;
  if (b0 > 0) if (b0 < 255) goto label9997;
    else in_width[k]=in_width[k]-alpha;
  } 

@ @<Replace |z|...@>=
{@+alpha=16;
while (z >= 040000000) 
  {@+z=z/2;alpha=alpha+alpha;
  } 
beta=256/alpha;alpha=alpha*z;
} 

@ A \.{DVI}-reading program usually works with font files instead of
\.{TFM} files, so \.{DVItype} is atypical in that respect. Font files
should, however, contain exactly the same character width data that is
found in the corresponding \.{TFM}s; check sums are used to help
ensure this. In addition, font files usually also contain the widths of
characters in pixels, since the device-independent character widths of
\.{TFM} files are generally not perfect multiples of pixels.

The |pixel_width| array contains this information; when |width[k]| is the
device-independent width of some character in \.{DVI} units, |pixel_width[k]|
is the corresponding width of that character in an actual font.
The macro |char_pixel_width| is set up to be analogous to |char_width|.

@d char_pixel_width(X)	pixel_width[width_base[X]+char_width_end

@<Glob...@>=
int @!pixel_width[max_widths+1]; /*actual character widths,
  in pixels*/ 
double @!conv; /*converts \.{DVI} units to pixels*/ 
double @!true_conv; /*converts unmagnified \.{DVI} units to pixels*/ 
int @!numerator, @!denominator; /*stated conversion ratio*/ 
int @!mag; /*magnification factor times 1000*/ 

@ The following code computes pixel widths by simply rounding the \.{TFM}
widths to the nearest integer number of pixels, based on the conversion factor
|conv| that converts \.{DVI} units to pixels. However, such a simple
formula will not be valid for all fonts, and it will often give results that
are off by $\pm1$ when a low-resolution font has been carefully
hand-fitted. For example, a font designer often wants to make the letter `m'
a pixel wider or narrower in order to make the font appear more consistent.
\.{DVI}-to-printer programs should therefore input the correct pixel width
information from font files whenever there is a chance that it may differ.
A warning message may also be desirable in the case that at least one character
is found whose pixel width differs from |conv*width| by more than a full pixel.
@^system dependencies@>

@d pixel_round(X)	round(conv*(X))

@<Move the widths from |in_width| to |width|, and append |pixel_width| values@>=
if (in_width[0]!=0) goto label9997; /*the first width should be zero*/ 
width_base[nf]=width_ptr-font_bc[nf];
if (wp > 0) for (k=width_ptr; k<=wp-1; k++) 
  if (width[k]==0) 
    {@+width[k]=invalid_width;pixel_width[k]=0;
    } 
  else{@+width[k]=in_width[width[k]];
    pixel_width[k]=pixel_round(width[k]);
    } 

@*Optional modes of output.
\.{DVItype} will print different quantities of information based on some
options that the user must specify: The |out_mode| level is set to one of
five values (|errors_only|, |terse|, |mnemonics_only|,
|verbose|, |the_works|), giving
different degrees of output; and the listing can be confined to a
restricted subset of the pages by specifying the desired starting page and
the maximum number of pages. Furthermore there is an option to specify the
resolution of an assumed discrete output device, so that pixel-oriented
calculations will be shown; and there is an option to override the
magnification factor that is stated in the \.{DVI} file.

The starting page is specified by giving a sequence of 1 to 10 numbers or
asterisks separated by dots. For example, the specification `\.{1.*.-5}'
can be used to refer to a page output by \TeX\ when $\.{\\count0}=1$
and $\.{\\count2}=-5$. (Recall that |bop| commands in a \.{DVI} file
are followed by ten `count' values.) An asterisk matches any number,
so the `\.*' in `\.{1.*.-5}' means that \.{\\count1} is ignored when
specifying the first page. If several pages match the given specification,
\.{DVItype} will begin with the earliest such page in the file. The
default specification `\.*' (which matches all pages) therefore denotes
the page at the beginning of the file.

When \.{DVItype} begins, it engages the user in a brief dialog so that the
options will be specified. This part of \.{DVItype} requires nonstandard
\PASCAL\ constructions to handle the online interaction; so it may be
preferable in some cases to omit the dialog and simply to stick to the
default options (|out_mode==the_works|, starting page `\.*',
|max_pages==1000000|, |resolution==300.0|, |new_mag==0|).  On other hand, the
system-dependent routines that are needed are not complicated, so it will
not be terribly difficult to introduce them.
@^system dependencies@>

@d errors_only	0 /*value of |out_mode| when minimal printing occurs*/ 
@d terse	1 /*value of |out_mode| for abbreviated output*/ 
@d mnemonics_only	2 /*value of |out_mode| for medium-quantity output*/ 
@d verbose	3 /*value of |out_mode| for detailed tracing*/ 
@d the_works	4 /*|verbose|, plus check of postamble if |random_reading|*/ 

@<Glob...@>=
uint8_t @!out_mode; /*controls the amount of output*/ 
int @!max_pages; /*at most this many |bop dotdot eop| pages will be printed*/ 
double @!resolution; /*pixels per inch*/ 
int @!new_mag; /*if positive, overrides the postamble's magnification*/ 

@ The starting page specification is recorded in two global arrays called
|start_count| and |start_there|. For example, `\.{1.*.-5}' is represented
by |start_there[0]==true|, |start_count[0]==1|, |start_there[1]==false|,
|start_there[2]==true|, |start_count[2]==-5|.
We also set |start_vals==2|, to indicate that count 2 was the last one
mentioned. The other values of |start_count| and |start_there| are not
important, in this example.

@<Glob...@>=
int @!start_count[10]; /*count values to select starting page*/ 
bool @!start_there[10]; /*is the |start_count| value relevant?*/ 
uint8_t @!start_vals; /*the last count considered significant*/ 
int @!count[10]; /*the count values on the current page*/ 

@ @<Set init...@>=
out_mode=the_works;max_pages=1000000;start_vals=0;start_there[0]=false;

@ Here is a simple subroutine that tests if the current page might be the
starting page.

@p bool start_match(void) /*does |count| match the starting spec?*/ 
{@+int k; /*loop index*/ 
bool @!match; /*does everything match so far?*/ 
match=true;
for (k=0; k<=start_vals; k++) 
  if (start_there[k]&&(start_count[k]!=count[k])) match=false;
return match;
} 

@ The |input_ln| routine waits for the user to type a line at his or her
terminal; then it puts ASCII-code equivalents for the characters on that line
into the |buffer| array. The |term_in| file is used for terminal input,
and |term_out| for terminal output.
@^system dependencies@>

@<Glob...@>=
ASCII_code @!buffer[terminal_line_length+1];
text_file @!term_in; /*the terminal, considered as an input file*/ 
text_file @!term_out; /*the terminal, considered as an output file*/ 
FILE *output;

@ Since the terminal is being used for both input and output, some systems
need a special routine to make sure that the user can see a prompt message
before waiting for input based on that message. (Otherwise the message
may just be sitting in a hidden buffer somewhere, and the user will have
no idea what the program is waiting for.) We shall invoke a system-dependent
subroutine |update_terminal| in order to avoid this problem.
@^system dependencies@>

@d update_terminal	fflush(term_out.f) /*empty the terminal output buffer*/

@ During the dialog, \.{DVItype} will treat the first blank space in a
line as the end of that line. Therefore |input_ln| makes sure that there
is always at least one blank space in |buffer|.
@^system dependencies@>

@p void input_ln(void) /*inputs a line from the terminal*/ 
{@+uint8_t k;
update_terminal;if(!term_in.f)term_in.f=stdin,get(term_in);
if (eoln(term_in)) read_ln(term_in);
k=0;
while ((k < terminal_line_length)&&!eoln(term_in)) 
  {@+buffer[k]=xord[term_in.d];incr(k);get(term_in);
  } 
buffer[k]=' ';
} 

@ The global variable |buf_ptr| is used while scanning each line of input;
it points to the first unread character in |buffer|.

@<Glob...@>=
uint8_t @!buf_ptr; /*the number of characters read*/ 

@ Here is a routine that scans a (possibly signed) integer and computes
the decimal value. If no decimal integer starts at |buf_ptr|, the
value 0 is returned. The integer should be less than $2^{31}$ in
absolute value.

@p int get_integer(void)
{@+int x; /*accumulates the value*/ 
bool @!negative; /*should the value be negated?*/ 
if (buffer[buf_ptr]=='-') 
  {@+negative=true;incr(buf_ptr);
  } 
else negative=false;
x=0;
while ((buffer[buf_ptr] >= '0')&&(buffer[buf_ptr] <= '9')) 
  {@+x=10*x+buffer[buf_ptr]-'0';incr(buf_ptr);
  } 
if (negative) return-x;@+else return x;
} 

@ The selected options are put into global variables by the |dialog|
procedure, which is called just as \.{DVItype} begins.
@^system dependencies@>

@p void dialog(void)
{@+
int k; /*loop variable*/ 
term_out.f=stdout; /*prepare the terminal for output*/
write_ln(term_out, banner);
@<Determine the desired |out_mode|@>;
@<Determine the desired |start_count| values@>;
@<Determine the desired |max_pages|@>;
@<Determine the desired |resolution|@>;
@<Determine the desired |new_mag|@>;
@<Print all the selected options@>;
} 

@ @<Determine the desired |out_mode|@>=
label1: write(term_out,"Output level (default=4, ? for help): ");
out_mode=the_works;input_ln();
if (buffer[0]!=' ') 
  if ((buffer[0] >= '0')&&(buffer[0] <= '4')) out_mode=buffer[0]-'0';
  else{@+write(term_out,"Type 4 for complete listing,");
    write(term_out," 0 for errors and fonts only,");
    write_ln(term_out," 1 or 2 or 3 for something in between.");
    goto label1;
    } 

@ @<Determine the desired |start...@>=
label2: write(term_out,"Starting page (default=*): ");
start_vals=0;start_there[0]=false;
input_ln();buf_ptr=0;k=0;
if (buffer[0]!=' ') 
  @/do@+{if (buffer[buf_ptr]=='*') 
    {@+start_there[k]=false;incr(buf_ptr);
    } 
  else{@+start_there[k]=true;start_count[k]=get_integer();
    } 
  if ((k < 9)&&(buffer[buf_ptr]=='.')) 
    {@+incr(k);incr(buf_ptr);
    } 
  else if (buffer[buf_ptr]==' ') start_vals=k;
  else{@+write(term_out,"Type, e.g., 1.*.-5 to specify the ");
    write_ln(term_out,"first page with \\count0=1, \\count2=-5.");
    goto label2;
    } 
  }@+ while (!(start_vals==k))

@ @<Determine the desired |max_pages|@>=
label3: write(term_out,"Maximum number of pages (default=1000000): ");
max_pages=1000000;input_ln();buf_ptr=0;
if (buffer[0]!=' ') 
  {@+max_pages=get_integer();
  if (max_pages <= 0) 
    {@+write_ln(term_out,"Please type a positive number.");
    goto label3;
    } 
  } 

@ @<Determine the desired |resolution|@>=
label4: write(term_out,"Assumed device resolution");
write(term_out," in pixels per inch (default=300/1): ");
resolution=300.0;input_ln();buf_ptr=0;
if (buffer[0]!=' ') 
  {@+k=get_integer();
  if ((k > 0)&&(buffer[buf_ptr]=='/')&&
    (buffer[buf_ptr+1] > '0')&&(buffer[buf_ptr+1] <= '9')) 
    {@+incr(buf_ptr);resolution=k/(double)get_integer();
    } 
  else{@+write(term_out,"Type a ratio of positive integers;");
    write_ln(term_out," (1 pixel per mm would be 254/10).");
    goto label4;
    } 
  } 

@ @<Determine the desired |new_mag|@>=
label5: write(term_out,"New magnification (default=0 to keep the old one): ");
new_mag=0;input_ln();buf_ptr=0;
if (buffer[0]!=' ') 
  if ((buffer[0] >= '0')&&(buffer[0] <= '9')) new_mag=get_integer();
  else{@+write(term_out,"Type a positive integer to override ");
    write_ln(term_out,"the magnification in the DVI file.");
    goto label5;
    } 

@ After the dialog is over, we print the options so that the user
can see what \.{DVItype} thought was specified.

@<Print all the selected options@>=
print_ln("Options selected:");
@.Options selected@>
print("  Starting page = ");
for (k=0; k<=start_vals; k++) 
  {@+if (start_there[k]) print("%d",start_count[k]);
  else print("*");
  if (k < start_vals) print(".");
  else print_ln(" ");
  } 
print_ln("  Maximum number of pages = %d", max_pages);
print("  Output level = %d", out_mode);
switch (out_mode) {
case errors_only: print_ln(" (showing bops, fonts, and error messages only)");@+break;
case terse: print_ln(" (terse)");@+break;
case mnemonics_only: print_ln(" (mnemonics)");@+break;
case verbose: print_ln(" (verbose)");@+break;
case the_works: if (random_reading) print_ln(" (the works)");
  else{@+out_mode=verbose;
    print_ln(" (the works: same as level 3 in this DVItype)");
    } 
} @/
print_ln("  Resolution = %12.8f pixels per inch", resolution);
if (new_mag > 0) print_ln("  New magnification factor = %8.3f", new_mag/(double)1000)

@*Defining fonts.
When |out_mode==the_works|, \.{DVItype} reads the postamble first and loads
all of the fonts defined there; then it processes the pages. In this
case, a \\{fnt\_def} command should match a previous definition if and only
if the \\{fnt\_def} being processed is not in the postamble. But if
|out_mode < the_works|, \.{DVItype} reads the pages first and the postamble
last, so the conventions are reversed: a \\{fnt\_def} should match a previous
\\{fnt\_def} if and only if the current one is a part of the postamble.

A global variable |in_postamble| is provided to tell whether we are
processing the postamble or not.

@<Glob...@>=
bool @!in_postamble; /*are we reading the postamble?*/ 

@ @<Set init...@>=
in_postamble=false;

@ The following subroutine does the necessary things when a \\{fnt\_def}
command is being processed.

@p void define_font(int @!e) /*|e| is an external font number*/ 
{@+uint8_t f;
int @!p; /*length of the area/directory spec*/ 
int @!n; /*length of the font name proper*/ 
int @!c, @!q, @!d, @!m; /*check sum, scaled size, design size, magnification*/ 
uint8_t @!r; /*index into |cur_name|*/ 
int @!j, @!k; /*indices into |names|*/ 
bool @!mismatch; /*do names disagree?*/ 
if (nf==max_fonts) abort("DVItype capacity exceeded (max fonts=%d)!", max_fonts);
@.DVItype capacity exceeded...@>
font_num[nf]=e;f=0;
while (font_num[f]!=e) incr(f);
@<Read the font parameters into position for font |nf|, and print the font name@>;
if (((out_mode==the_works)&&in_postamble)||@|
   ((out_mode < the_works)&&!in_postamble)) 
  {@+if (f < nf) print_ln("---this font was already defined!");
@.this font was already defined@>
  } 
else{@+if (f==nf) print_ln("---this font wasn't loaded before!");
@.this font wasn't loaded before@>
  } 
if (f==nf) @<Load the new font, unless there are problems@>@;
else@<Check that the current font definition matches the old one@>;
} 

@ @<Check that the current...@>=
{@+if (font_check_sum[f]!=c) 
  print_ln("---check sum doesn't match previous definition!");
@.check sum doesn't match@>
if (font_scaled_size[f]!=q) 
  print_ln("---scaled size doesn't match previous definition!");
@.scaled size doesn't match@>
if (font_design_size[f]!=d) 
  print_ln("---design size doesn't match previous definition!");
@.design size doesn't match@>
j=font_name[f];k=font_name[nf];
if (font_name[f+1]-j!=font_name[nf+1]-k) mismatch=true;
else{@+mismatch=false;
  while (j < font_name[f+1]) 
    {@+if (names[j]!=names[k]) mismatch=true;
    incr(j);incr(k);
    } 
  } 
if (mismatch) print_ln("---font name doesn't match previous definition!");
@.font name doesn't match@>
} 

@ @<Read the font parameters into position for font |nf|...@>=
c=signed_quad();font_check_sum[nf]=c;@/
q=signed_quad();font_scaled_size[nf]=q;@/
d=signed_quad();font_design_size[nf]=d;@/
if ((q <= 0)||(d <= 0)) m=1000;
else m=round((1000.0*conv*q)/(double)(true_conv*d));
p=get_byte();n=get_byte();
if (font_name[nf]+n+p > name_size) 
  abort("DVItype capacity exceeded (name size=%d)!", name_size);
@.DVItype capacity exceeded...@>
font_name[nf+1]=font_name[nf]+n+p;
if (showing) print(": ");
   /*when |showing| is true, the font number has already been printed*/ 
else print("Font %d: ", e);
if (n+p==0) print("null font name!");
@.null font name@>
else for (k=font_name[nf]; k<=font_name[nf+1]-1; k++) names[k]=get_byte();
print_font(nf);
if (!showing) if (m!=1000) print(" scaled %d", m)
@.scaled@>

@ @<Load the new font, unless there are problems@>=
{@+@<Move font name into the |cur_name| string@>;
open_tfm_file();
if (eof(tfm_file)) 
  print("---not loaded, TFM file can't be opened!");
@.TFM file can\'t be opened@>
else{@+if ((q <= 0)||(q >= 01000000000)) 
    print("---not loaded, bad scale (%d)!", q);
@.bad scale@>
  else if ((d <= 0)||(d >= 01000000000)) 
    print("---not loaded, bad design size (%d)!", d);
@.bad design size@>
  else if (in_TFM(q)) @<Finish loading the new font info@>;
  } 
if (out_mode==errors_only) print_ln(" ");
} 

@ @<Finish loading...@>=
{@+font_space[nf]=q/6; /*this is a 3-unit ``thin space''*/ 
if ((c!=0)&&(tfm_check_sum!=0)&&(c!=tfm_check_sum)) 
  {@+print_ln("---beware: check sums do not agree!");
@.beware: check sums do not agree@>
@.check sums do not agree@>
  print_ln("   (%d vs. %d)", c, tfm_check_sum);
  print("   ");
  } 
if (abs(tfm_design_size-d) > 2) 
  {@+print_ln("---beware: design sizes do not agree!");
@.beware: design sizes do not agree@>
@.design sizes do not agree@>
  print_ln("   (%d vs. %d)", d, tfm_design_size);
  print("   ");
  } 
print("---loaded at size %d DVI units", q);
d=round((100.0*conv*q)/(double)(true_conv*d));
if (d!=100) 
  {@+print_ln(" ");print(" (this font is magnified %d%%)", d);
  } 
@.this font is magnified@>
incr(nf); /*now the new font is officially present*/ 
} 

@ If |p==0|, i.e., if no font directory has been specified, \.{DVItype}
is supposed to use the default font directory, which is a
system-dependent place where the standard fonts are kept.
The string variable |default_directory| contains the name of this area.
@^system dependencies@>

@d default_directory_name	"TeXfonts/" /*change this to the correct name*/
@d default_directory_name_length	9 /*change this to the correct length*/ 

@<Glob...@>=
uint8_t @!default_directory0[default_directory_name_length+1], *const @!default_directory = @!default_directory0-1;

@ @<Set init...@>=
strcpy(default_directory+1, default_directory_name);

@ The string |cur_name| is supposed to be set to the external name of the
\.{TFM} file for the current font. This usually means that we need to
prepend the name of the default directory, and
to append the suffix `\.{.TFM}'. Furthermore, we change lower case letters
to upper case, since |cur_name| is a \PASCAL\ string.
@^system dependencies@>

@<Move font name into the |cur_name| string@>=
if (p==0) 
  {@+for (k=1; k<=default_directory_name_length; k++) 
    cur_name[k]=default_directory[k];
  r=default_directory_name_length;
  } 
else r=0;
for (k=font_name[nf]; k<=font_name[nf+1]-1; k++) 
  {@+incr(r);
  if (r+4 > name_length) 
    abort("DVItype capacity exceeded (max font name length=%d)!", name_length);
@.DVItype capacity exceeded...@>
  if ((names[k] >= 'a')&&(names[k] <= 'z')) 
      cur_name[r]=xchr[names[k]-040];
  else cur_name[r]=xchr[names[k]];
  } 
cur_name[r+1]= '.' ;cur_name[r+2]= 'T' ;cur_name[r+3]= 'F' ;cur_name[r+4]= 'M' 
;cur_name[r+5]=0

@*Low level output routines.
Simple text in the \.{DVI} file is saved in a buffer until |line_length-2|
characters have accumulated, or until some non-simple \.{DVI} operation
occurs. Then the accumulated text is printed on a line, surrounded by
brackets. The global variable |text_ptr| keeps track of the number of
characters currently in the buffer.

@<Glob...@>=
uint8_t @!text_ptr; /*the number of characters in |text_buf|*/ 
ASCII_code @!text_buf0[line_length], *const @!text_buf = @!text_buf0-1; /*saved characters*/ 

@ @<Set init...@>=
text_ptr=0;

@ The |flush_text| procedure will empty the buffer if there is something in it.

@p void flush_text(void)
{@+int k; /*index into |text_buf|*/ 
if (text_ptr > 0) 
  {@+if (out_mode > errors_only) 
    {@+print("[");
    for (k=1; k<=text_ptr; k++) print("%c",xchr[text_buf[k]]);
    print_ln("]");
    } 
  text_ptr=0;
  } 
} 

@ And the |out_text| procedure puts something in it.

@p void out_text(ASCII_code c)
{@+if (text_ptr==line_length-2) flush_text();
incr(text_ptr);text_buf[text_ptr]=c;
} 

@*Translation to symbolic form.
The main work of \.{DVItype} is accomplished by the |do_page| procedure,
which produces the output for an entire page, assuming that the |bop|
command for that page has already been processed. This procedure is
essentially an interpretive routine that reads and acts on the \.{DVI}
commands.

@ The definition of \.{DVI} files refers to six registers,
$(h,v,w,x,y,z)$, which hold integer values in \.{DVI} units.  In practice,
we also need registers |hh| and |vv|, the pixel analogs of $h$ and $v$,
since it is not always true that |hh==pixel_round(h)| or
|vv==pixel_round(v)|.

The stack of $(h,v,w,x,y,z)$ values is represented by eight arrays
called |hstack|, \dots, |zstack|, |hhstack|, and |vvstack|.

@<Glob...@>=
int @!h, @!v, @!w, @!x, @!y, @!z, @!hh, @!vv; /*current state values*/ 

  int @!hstack[stack_size+1], @!vstack[stack_size+1], @!wstack[stack_size+1], @!xstack[stack_size+1], @!ystack[stack_size+1], @!zstack[stack_size+1]; /*pushed down values in \.{DVI} units*/ 

  int @!hhstack[stack_size+1], @!vvstack[stack_size+1]; /*pushed down values in pixels*/ 

@ Three characteristics of the pages (their |max_v|, |max_h|, and
|max_s|) are specified in the postamble, and a warning message
is printed if these limits are exceeded. Actually |max_v| is set to
the maximum height plus depth of a page, and |max_h| to the maximum width,
for purposes of page layout. Since characters can legally be set outside
of the page boundaries, it is not an error when |max_v| or |max_h| is
exceeded. But |max_s| should not be exceeded.

The postamble also specifies the total number of pages; \.{DVItype}
checks to see if this total is accurate.

@<Glob...@>=
int @!max_v; /*the value of |abs(v)| should probably not exceed this*/ 
int @!max_h; /*the value of |abs(h)| should probably not exceed this*/ 
int @!max_s; /*the stack depth should not exceed this*/ 
int @!max_v_so_far, @!max_h_so_far, @!max_s_so_far; /*the record high levels*/ 
int @!total_pages; /*the stated total number of pages*/ 
int @!page_count; /*the total number of pages seen so far*/ 

@ @<Set init...@>=
max_v=017777777777-99;max_h=017777777777-99;max_s=stack_size+1;@/
max_v_so_far=0;max_h_so_far=0;max_s_so_far=0;page_count=0;

@ Before we get into the details of |do_page|, it is convenient to
consider a simpler routine that computes the first parameter of each
opcode.

@d four_cases(X)	case X: case X+1: case X+2: case X+3
@d eight_cases(X)	four_cases(X): four_cases(X+4)
@d sixteen_cases(X)	eight_cases(X): eight_cases(X+8)
@d thirty_two_cases(X)	sixteen_cases(X): sixteen_cases(X+16)
@d sixty_four_cases(X)	thirty_two_cases(X): thirty_two_cases(X+32)

@p int first_par(eight_bits o)
{@+switch (o) {
sixty_four_cases(set_char_0): sixty_four_cases(set_char_0+64):
  return o-set_char_0;@+break;
case set1: case put1: case fnt1: case xxx1: case fnt_def1: return get_byte();@+break;
case set1+1: case put1+1: case fnt1+1: case xxx1+1: case fnt_def1+1: return get_two_bytes();@+break;
case set1+2: case put1+2: case fnt1+2: case xxx1+2: case fnt_def1+2: return get_three_bytes();@+break;
case right1: case w1: case x1: case down1: case y1: case z1: return signed_byte();@+break;
case right1+1: case w1+1: case x1+1: case down1+1: case y1+1: case z1+1: return signed_pair();@+break;
case right1+2: case w1+2: case x1+2: case down1+2: case y1+2: case z1+2: return signed_trio();@+break;
case set1+3: case set_rule: case put1+3: case put_rule: case right1+3: case w1+3: case x1+3: case down1+3: case y1+3: case z1+3: 
  case fnt1+3: case xxx1+3: case fnt_def1+3: return signed_quad();@+break;
case nop: case bop: case eop: case push: case pop: case pre: case post: case post_post: undefined_commands: return 0;@+break;
case w0: return w;@+break;
case x0: return x;@+break;
case y0: return y;@+break;
case z0: return z;@+break;
sixty_four_cases(fnt_num_0): return o-fnt_num_0;
} 
} 

@ Here is another subroutine that we need: It computes the number of
pixels in the height or width of a rule. Characters and rules will line up
properly if the sizes are computed precisely as specified here.  (Since
|conv| is computed with some floating-point roundoff error, in a
machine-dependent way, format designers who are tailoring something for a
particular resolution should not plan their measurements to come out to an
exact integer number of pixels; they should compute things so that the
rule dimensions are a little less than an integer number of pixels, e.g.,
4.99 instead of 5.00.)

@p int rule_pixels(int x)
   /*computes $\lceil|conv|\cdot x\rceil$*/ 
{@+int n;
n=trunc(conv*x);
if (n < conv*x) return n+1;@+else return n;
} 

@ Strictly speaking, the |do_page| procedure is really a function with
side effects, not a `\&{procedure}'\thinspace; it returns the value |false|
if \.{DVItype} should be aborted because of some unusual happening. The
subroutine is organized as a typical interpreter, with a multiway branch
on the command code followed by |goto| statements leading to routines that
finish up the activities common to different commands. We will use the
following labels:

@ Some \PASCAL\ compilers severely restrict the length of procedure bodies,
so we shall split |do_page| into two parts, one of which is
called |special_cases|. The different parts communicate with each other
via the global variables mentioned above, together with the following ones:

@<Glob...@>=
int @!s; /*current stack size*/ 
int @!ss; /*stack size to print*/ 
int @!cur_font; /*current internal font number*/ 
bool @!showing; /*is the current command being translated in full?*/ 

@ Here is the overall setup.

@p@t\4@>@<Declare the function called |special_cases|@>@;
bool do_page(void)
{@+
eight_bits o; /*operation code of the current command*/ 
int @!p, @!q; /*parameters of the current command*/ 
int @!a; /*byte number of the current command*/ 
int @!hhh; /*|h|, rounded to the nearest pixel*/ 
cur_font=invalid_font; /*set current font undefined*/ 
s=0;h=0;v=0;w=0;x=0;y=0;z=0;hh=0;vv=0;
   /*initialize the state variables*/ 
while (true) @<Translate the next command in the \.{DVI} file; |return true|
if it was |eop|; |goto 9998| if premature termination is needed@>;
label9998: print_ln("!");return false;
}

@ Commands are broken down into ``major'' and ``minor'' categories:
A major command is always shown in full, while a minor one is
put into the buffer in abbreviated form. Minor commands, which
account for the bulk of most \.{DVI} files, involve horizontal spacing
and the typesetting of characters in a line; these are shown in full
only if |out_mode >= verbose|.

@d show(X,...) {@+flush_text();showing=true;print("%d: "X,a,##__VA_ARGS__);
  } 
@d major(...)	if (out_mode > errors_only) show(__VA_ARGS__)
@d minor(X,...) if (out_mode > terse)
  {@+showing=true;print("%d: "X,a,##__VA_ARGS__);
  } 
@d error(...) if (!showing) show(__VA_ARGS__)@;else print(" "__VA_ARGS__)

@<Translate the next command...@>=
{@+a=cur_loc;showing=false;
o=get_byte();p=first_par(o);
if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
@<Start translation of command |o| and |goto| the appropriate label to finish the
job@>;
fin_set: @<Finish a command that either sets or puts a character, then |goto move_right|
or |done|@>;
fin_rule: @<Finish a command that either sets or puts a rule, then |goto move_right|
or |done|@>;
move_right: @<Finish a command that sets |h:=h+q|, then |goto done|@>;
show_state: @<Show the values of |ss|, |h|, |v|, |w|, |x|, |y|, |z|, |hh|, and |vv|;
then |goto done|@>;
done: if (showing) print_ln(" ");
} 

@ The multiway switch in |first_par|, above, was organized by the length
of each command; the one in |do_page| is organized by the semantics.

@<Start translation...@>=
if (o < set_char_0+128) @<Translate a |set_char| command@>@;
else switch (o) {
  four_cases(set1): {@+major("set%d %d", o-set1+1, p);goto fin_set;
    } 
  four_cases(put1): {@+major("put%d %d", o-put1+1, p);goto fin_set;
    } 
  case set_rule: {@+major("setrule");goto fin_rule;
    } 
  case put_rule: {@+major("putrule");goto fin_rule;
    } 
  @t\4@>@<Cases for commands |nop|, |bop|, \dots, |pop|@>@;
  @t\4@>@<Cases for horizontal motion@>@;
  default:if (special_cases(o, p, a)) goto done;@+else goto label9998;
  } 

@ @<Declare the function called |special_cases|@>=
bool special_cases(eight_bits @!o, int @!p, int @!a)
{@+
int q; /*parameter of the current command*/ 
int @!k; /*loop index*/ 
bool @!bad_char; /*has a non-ASCII character code appeared in this \\{xxx}?*/ 
int @!vvv; /*|v|, rounded to the nearest pixel*/ 
switch (o) {
@t\4@>@<Cases for vertical motion@>@;
@t\4@>@<Cases for fonts@>@;
four_cases(xxx1): @<Translate an |xxx| command and |goto done|@>@;
case pre: {@+error("preamble command within a page!");goto label9998;
  } 
@.preamble command within a page@>
case post: case post_post: {@+error("postamble command within a page!");goto label9998;
@.postamble command within a page@>
  } 
default:{@+error("undefined command %d!", o);
  goto done;
@.undefined command@>
  } 
} 
move_down: @<Finish a command that sets |v:=v+p|, then |goto done|@>;
change_font: @<Finish a command that changes the current font, then |goto done|@>;
label9998: return false;
done: return true;
} 

@ @<Cases for commands |nop|, |bop|, \dots, |pop|@>=
case nop: {@+minor("nop");goto done;
  } 
case bop: {@+error("bop occurred before eop!");goto label9998;
@.bop occurred before eop@>
  } 
case eop: {@+major("eop");
  if (s!=0) error("stack not empty at end of page (level %d)!", s);
@.stack not empty...@>
  print_ln(" ");return true;
  } 
case push: {@+major("push");
  if (s==max_s_so_far) 
    {@+max_s_so_far=s+1;
    if (s==max_s) error("deeper than claimed in postamble!");
@.deeper than claimed...@>
@.push deeper than claimed...@>
    if (s==stack_size) 
      {@+error("DVItype capacity exceeded (stack size=%d)", stack_size);
        goto label9998;
      } 
    } 
  hstack[s]=h;vstack[s]=v;wstack[s]=w;
  xstack[s]=x;ystack[s]=y;zstack[s]=z;
  hhstack[s]=hh;vvstack[s]=vv;incr(s);ss=s-1;goto show_state;
  } 
case pop: {@+major("pop");
  if (s==0) error("(illegal at level zero)!");
  else{@+decr(s);hh=hhstack[s];vv=vvstack[s];
    h=hstack[s];v=vstack[s];w=wstack[s];
    x=xstack[s];y=ystack[s];z=zstack[s];
    } 
  ss=s;goto show_state;
  } 

@ Rounding to the nearest pixel is best done in the manner shown here, so as
to be inoffensive to the eye: When the horizontal motion is small, like a
kern, |hh| changes by rounding the kern; but when the motion is large, |hh|
changes by rounding the true position |h| so that accumulated rounding errors
disappear. We allow a larger space in the negative direction than in
the positive one, because \TeX\ makes comparatively
large backspaces when it positions accents.

@d out_space(X, Y)	if ((p >= font_space[cur_font])||(p <= -4*font_space[cur_font])) 
    {@+out_text(' ');hh=pixel_round(h+p);
    } 
  else hh=hh+pixel_round(p);
  minor(X" %d", Y, p);q=p;goto move_right

@<Cases for horizontal motion@>=
four_cases(right1): {@+out_space("right%d", o-right1+1);
  } 
case w0: four_cases(w1): {@+w=p;out_space("w%d", o-w0);
  } 
case x0: four_cases(x1): {@+x=p;out_space("x%d", o-x0);
  } 

@ Vertical motion is done similarly, but with the threshold between
``small'' and ``large'' increased by a factor of five. The idea is to make
fractions like ``$1\over2$'' round consistently, but to absorb accumulated
rounding errors in the baseline-skip moves.

@d out_vmove(X, Y)	if (abs(p) >= 5*font_space[cur_font]) vv=pixel_round(v+p);
  else vv=vv+pixel_round(p);
  major(X" %d", Y, p);goto move_down

@<Cases for vertical motion@>=
four_cases(down1): {@+out_vmove("down%d", o-down1+1);
  } 
case y0: four_cases(y1): {@+y=p;out_vmove("y%d", o-y0);
  } 
case z0: four_cases(z1): {@+z=p;out_vmove("z%d", o-z0);
  } 

@ @<Cases for fonts@>=
sixty_four_cases(fnt_num_0): {@+major("fntnum%d", p);
  goto change_font;
  } 
four_cases(fnt1): {@+major("fnt%d %d", o-fnt1+1, p);
  goto change_font;
  } 
four_cases(fnt_def1): {@+major("fntdef%d %d", o-fnt_def1+1, p);
  define_font(p);goto done;
  } 

@ @<Translate an |xxx| command and |goto done|@>=
{@+major("xxx '");bad_char=false;
if (p < 0) error("string of negative length!");
@.string of negative length@>
for (k=1; k<=p; k++) 
  {@+q=get_byte();
  if ((q < ' ')||(q > '~')) bad_char=true;
  if (showing) print("%c",xchr[q]);
  } 
if (showing) print("'");
if (bad_char) error("non-ASCII character in xxx command!");
@.non-ASCII character...@>
goto done;
} 

@ @<Translate a |set_char|...@>=
{@+if ((o > ' ')&&(o <= '~')) 
  {@+out_text(p);minor("setchar%d", p);
  } 
else major("setchar%d", p);
goto fin_set;
} 

@ @<Finish a command that either sets or puts a character...@>=
if (p < 0) p=255-((-1-p)%256);
else if (p >= 256) p=p%256; /*width computation for oriental fonts*/ 
@^oriental characters@>@^Chinese characters@>@^Japanese characters@>
if ((p < font_bc[cur_font])||(p > font_ec[cur_font])) q=invalid_width;
else q=char_width(cur_font)(p);
if (q==invalid_width) 
  {@+error("character %d invalid in font ", p);
@.character $c$ invalid...@>
  print_font(cur_font);
  if (cur_font!=invalid_font) 
     print("!"); /*the invalid font has `\.!' in its name*/
  } 
if (o >= put1) goto done;
if (q==invalid_width) q=0;
else hh=hh+char_pixel_width(cur_font)(p);
goto move_right

@ @<Finish a command that either sets or puts a rule...@>=
q=signed_quad();
if (showing) 
  {@+print(" height %d, width %d", p, q);
  if (out_mode > mnemonics_only) 
    if ((p <= 0)||(q <= 0)) print(" (invisible)");
    else print(" (%dx%d pixels)", rule_pixels(p), rule_pixels(q));
  } 
if (o==put_rule) goto done;
if (showing) if (out_mode > mnemonics_only) print_ln(" ");
hh=hh+rule_pixels(q);goto move_right

@ A sequence of consecutive rules, or consecutive characters in a fixed-width
font whose width is not an integer number of pixels, can cause |hh| to drift
far away from a correctly rounded value. \.{DVItype} ensures that the
amount of drift will never exceed |max_drift| pixels.

Since \.{DVItype} is intended to diagnose strange errors, it checks
carefully to make sure that |h| and |v| do not get out of range.
Normal \.{DVI}-reading programs need not do this.

@d infinity	017777777777 /*$\infty$ (approximately)*/ 
@d max_drift	2 /*we insist that abs|(hh-pixel_round(h)) <= max_drift|*/ 

@<Finish a command that sets |h:=h+q|, then |goto done|@>=
if ((h > 0)&&(q > 0)) if (h > infinity-q) 
  {@+error("arithmetic overflow! parameter changed from %d to %d", q, infinity-h);
@.arithmetic overflow...@>
  q=infinity-h;
  } 
if ((h < 0)&&(q < 0)) if (-h > q+infinity) 
  {@+error("arithmetic overflow! parameter changed from %d to %d", q, (-h)-infinity);
  q=(-h)-infinity;
  } 
hhh=pixel_round(h+q);
if (abs(hhh-hh) > max_drift) 
  if (hhh > hh) hh=hhh-max_drift;
  else hh=hhh+max_drift;
if (showing) if (out_mode > mnemonics_only) 
  {@+print(" h:=%d", h);
  if (q >= 0) print("+");
  print("%d=%d, hh:=%d", q, h+q, hh);
  } 
h=h+q;
if (abs(h) > max_h_so_far) 
  {@+if (abs(h) > max_h+99) 
    {@+error("warning: |h|>%d!", max_h);
@.warning: |h|...@>
    max_h=abs(h);
    } 
  max_h_so_far=abs(h);
  } 
goto done

@ @<Finish a command that sets |v:=v+p|, then |goto done|@>=
if ((v > 0)&&(p > 0)) if (v > infinity-p) 
  {@+error("arithmetic overflow! parameter changed from %d to %d", p, infinity-v);
@.arithmetic overflow...@>
  p=infinity-v;
  } 
if ((v < 0)&&(p < 0)) if (-v > p+infinity) 
  {@+error("arithmetic overflow! parameter changed from %d to %d", p, (-v)-infinity);
  p=(-v)-infinity;
  } 
vvv=pixel_round(v+p);
if (abs(vvv-vv) > max_drift) 
  if (vvv > vv) vv=vvv-max_drift;
  else vv=vvv+max_drift;
if (showing) if (out_mode > mnemonics_only) 
  {@+print(" v:=%d", v);
  if (p >= 0) print("+");
  print("%d=%d, vv:=%d", p, v+p, vv);
  } 
v=v+p;
if (abs(v) > max_v_so_far) 
  {@+if (abs(v) > max_v+99) 
    {@+error("warning: |v|>%d!", max_v);
@.warning: |v|...@>
    max_v=abs(v);
    } 
  max_v_so_far=abs(v);
  } 
goto done

@ @<Show the values of |ss|, |h|, |v|, |w|, |x|, |y|, |z|...@>=
if (showing) if (out_mode > mnemonics_only) 
  {@+print_ln(" ");
  print("level %d:(h=%d,v=%d,w=%d,x=%d,y=%d,z=%d,hh=%d,vv=%d)", ss, h, v, w, x, y, z, hh, vv);
  } 
goto done

@ @<Finish a command that changes the current font...@>=
font_num[nf]=p;cur_font=0;
while (font_num[cur_font]!=p) incr(cur_font);
if (cur_font==nf) 
  {@+cur_font=invalid_font;
  error("invalid font selection: font %d was never defined!", p);
  } 
if (showing) if (out_mode > mnemonics_only) 
  {@+print(" current font is ");print_font(cur_font);
  } 
goto done

@*Skipping pages.
A routine that's much simpler than |do_page| is used to pass over
pages that are not being translated. The |skip_pages| subroutine
is assumed to begin just after the preamble has been read, or just
after a |bop| has been processed. It continues until either finding a
|bop| that matches the desired starting page specifications, or until
running into the postamble.

@p@t\4@>@<Declare the procedure called |scan_bop|@>@;
void skip_pages(bool @!bop_seen)
{@+ /*end of this subroutine*/ 
int p; /*a parameter*/ 
uint8_t @!k; /*command code*/ 
int @!down_the_drain; /*garbage*/ 
showing=false;
while (true) 
  {@+if (!bop_seen) 
    {@+scan_bop();
    if (in_postamble) return;
    if (!started) if (start_match()) 
      {@+started=true;return;
      } 
    } 
  @<Skip until finding |eop|@>;
  bop_seen=false;
  } 
}

@ @<Skip until finding |eop|@>=
@/do@+{if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
  k=get_byte();
  p=first_par(k);
  switch (k) {
  case set_rule: case put_rule: down_the_drain=signed_quad();@+break;
  four_cases(fnt_def1): {@+define_font(p);
    print_ln(" ");
    } @+break;
  four_cases(xxx1): while (p > 0)
    {@+down_the_drain=get_byte();decr(p);
    } @+break;
  case bop: case pre: case post: case post_post: undefined_commands: 
      bad_dvi("illegal command at byte %d", cur_loc-1)@;@+break;
@.illegal command at byte n@>
  default:do_nothing;
  } 
}@+ while (!(k==eop));

@ Global variables called |old_backpointer| and |new_backpointer|
are used to check whether the back pointers are properly set up.
Another one tells whether we have already found the starting page.

@<Glob...@>=
int @!old_backpointer; /*the previous |bop| command location*/ 
int @!new_backpointer; /*the current |bop| command location*/ 
bool @!started; /*has the starting page been found?*/ 

@ @<Set init...@>=
old_backpointer=-1;started=false;

@ The |scan_bop| procedure reads \.{DVI} commands following the preamble
or following |eop|, until finding either |bop| or the postamble.

@<Declare the procedure called |scan_bop|@>=
void scan_bop(void)
{@+uint8_t k; /*command code*/ 
@/do@+{if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
  k=get_byte();
  if ((k >= fnt_def1)&&(k < fnt_def1+4)) 
    {@+define_font(first_par(k));k=nop;
    } 
}@+ while (!(k!=nop));
if (k==post) in_postamble=true;
else{@+if (k!=bop) bad_dvi("byte %d is not bop", cur_loc-1);
@.byte n is not bop@>
  new_backpointer=cur_loc-1;incr(page_count);
  for (k=0; k<=9; k++) count[k]=signed_quad();
  if (signed_quad()!=old_backpointer
    ) print_ln("backpointer in byte %d should be %d!", cur_loc-4, old_backpointer);
@.backpointer...should be p@>
  old_backpointer=new_backpointer;
  } 
} 

@*Using the backpointers.
The routines in this section of the program are brought into play only
if |random_reading| is |true| (and only if |out_mode==the_works|).
First comes a routine that illustrates how to find the postamble quickly.

@<Find the postamble, working back from the end@>=
n=dvi_length();
if (n < 53) bad_dvi("only %d bytes long", n);
@.only n bytes long@>
m=n-4;
@/do@+{if (m==0) bad_dvi("all 223s");
@.all 223s@>
move_to_byte(m);k=get_byte();decr(m);
}@+ while (!(k!=223));
if (k!=id_byte) bad_dvi("ID byte is %d", k);
@.ID byte is wrong@>
move_to_byte(m-3);q=signed_quad();
if ((q < 0)||(q > m-33)) bad_dvi("post pointer %d at byte %d", q, m-3);
@.post pointer is wrong@>
move_to_byte(q);k=get_byte();
if (k!=post) bad_dvi("byte %d is not post", q);
@.byte n is not post@>
post_loc=q;first_backpointer=signed_quad()

@ Note that the last steps of the above code save the locations of the
|post| byte and the final |bop|.  We had better declare these global
variables, together with two more that we will need shortly.

@<Glob...@>=
int @!post_loc; /*byte location where the postamble begins*/ 
int @!first_backpointer; /*the pointer following |post|*/ 
int @!start_loc; /*byte location of the first page to process*/ 
int @!after_pre; /*byte location immediately following the preamble*/ 

@ The next little routine shows how the backpointers can be followed
to move through a \.{DVI} file in reverse order. Ordinarily a \.{DVI}-reading
program would do this only if it wants to print the pages backwards or
if it wants to find a specified starting page that is not necessarily the
first page in the file; otherwise it would of course be simpler and faster
just to read the whole file from the beginning.

@<Count the pages and move to the starting page@>=
q=post_loc;p=first_backpointer;start_loc=-1;
if (p < 0) in_postamble=true;
else{@+@/do@+{
     /*now |q| points to a |post| or |bop| command; |p >= 0| is prev pointer*/ 
    if (p > q-46) 
      bad_dvi("page link %d after byte %d", p, q);
@.page link wrong...@>
    q=p;move_to_byte(q);k=get_byte();
    if (k==bop) incr(page_count);
    else bad_dvi("byte %d is not bop", q);
@.byte n is not bop@>
    for (k=0; k<=9; k++) count[k]=signed_quad();
    p=signed_quad();
    if (start_match()) 
      {@+start_loc=q;old_backpointer=p;
      } 
  }@+ while (!(p < 0));
  if (start_loc < 0) abort("starting page number could not be found!");
@.starting page number...@>
  if (old_backpointer < 0) start_loc=after_pre; /*we want to check everything*/ 
  move_to_byte(start_loc);
  } 
if (page_count!=total_pages) 
  print_ln("there are really %d pages, not %d!", page_count, total_pages)
@.there are really n pages@>

@*Reading the postamble.
Now imagine that we are reading the \.{DVI} file and positioned just
four bytes after the |post| command. That, in fact, is the situation,
when the following part of \.{DVItype} is called upon to read, translate,
and check the rest of the postamble.

@p void read_postamble(void)
{@+int k; /*loop index*/ 
int @!p, @!q, @!m; /*general purpose registers*/ 
showing=false;post_loc=cur_loc-5;
print_ln("Postamble starts at byte %d.", post_loc);
@.Postamble starts at byte n@>
if (signed_quad()!=numerator) 
  print_ln("numerator doesn't match the preamble!");
@.numerator doesn't match@>
if (signed_quad()!=denominator) 
  print_ln("denominator doesn't match the preamble!");
@.denominator doesn't match@>
if (signed_quad()!=mag) if (new_mag==0) 
  print_ln("magnification doesn't match the preamble!");
@.magnification doesn't match@>
max_v=signed_quad();max_h=signed_quad();@/
print("maxv=%d, maxh=%d", max_v, max_h);@/
max_s=get_two_bytes();total_pages=get_two_bytes();@/
print_ln(", maxstackdepth=%d, totalpages=%d", max_s, total_pages);
if (out_mode < the_works) 
  @<Compare the \\{lust} parameters with the accumulated facts@>;
@<Process the font definitions of the postamble@>;
@<Make sure that the end of the file is well-formed@>;
} 

@ No warning is given when |max_h_so_far| exceeds |max_h| by less than~100,
since 100 units is invisibly small; it's approximately the wavelength of
visible light, in the case of \TeX\ output. Rounding errors can be expected
to make |h| and |v| slightly more than |max_h| and |max_v|, every once in
a~while; hence small discrepancies are not cause for alarm.

@<Compare the \\{lust}...@>=
{@+if (max_v+99 < max_v_so_far) 
  print_ln("warning: observed maxv was %d", max_v_so_far);
@.warning: observed maxv...@>
@.observed maxv was x@>
if (max_h+99 < max_h_so_far) 
  print_ln("warning: observed maxh was %d", max_h_so_far);
@.warning: observed maxh...@>
@.observed maxh was x@>
if (max_s < max_s_so_far) 
  print_ln("warning: observed maxstackdepth was %d", max_s_so_far);
@.warning: observed maxstack...@>
@.observed maxstackdepth was x@>
if (page_count!=total_pages) 
  print_ln("there are really %d pages, not %d!", page_count, total_pages);
} 
@.there are really n pages@>

@ When we get to the present code, the |post_post| command has
just been read.

@<Make sure that the end of the file is well-formed@>=
q=signed_quad();
if (q!=post_loc) 
  print_ln("bad postamble pointer in byte %d!", cur_loc-4);
@.bad postamble pointer@>
m=get_byte();
if (m!=id_byte) print_ln("identification in byte %d should be %d!", cur_loc-1, id_byte);
@.identification...should be n@>
k=cur_loc;m=223;
while ((m==223)&&!eof(dvi_file)) m=get_byte();
if (!eof(dvi_file)) bad_dvi("signature in byte %d should be 223", cur_loc-1)@;
@.signature...should be...@>
else if (cur_loc < k+4) 
  print_ln("not enough signature bytes at end of file (%d)", cur_loc-k);
@.not enough signature bytes...@>

@ @<Process the font definitions...@>=
@/do@+{k=get_byte();
if ((k >= fnt_def1)&&(k < fnt_def1+4)) 
  {@+p=first_par(k);define_font(p);print_ln(" ");k=nop;
  } 
}@+ while (!(k!=nop));
if (k!=post_post) 
  print_ln("byte %d is not postpost!", cur_loc-1)
@.byte n is not postpost@>

@*The main program.
Now we are ready to put it all together. This is where \.{DVItype} starts,
and where it ends.

@p int main(int argc, char **argv) { if (argc != 3) return 2;
if ((dvi_file.f=fopen(argv[1],"r"))==NULL) return 2;
if ((output=fopen(argv[2],"w"))==NULL) return 2;
initialize(); /*get all variables initialized*/
dialog(); /*set up all the options*/ 
@<Process the preamble@>;
if (out_mode==the_works)  /*|random_reading==true|*/ 
  {@+@<Find the postamble, working back from the end@>;
  in_postamble=true;read_postamble();in_postamble=false;
  @<Count the pages and move to the starting page@>;
  } 
skip_pages(false);
if (!in_postamble) @<Translate up to |max_pages| pages@>;
if (out_mode < the_works) 
  {@+if (!in_postamble) skip_pages(true);
  if (signed_quad()!=old_backpointer) 
    print_ln("backpointer in byte %d should be %d!", cur_loc-4, old_backpointer);
@.backpointer...should be p@>
  read_postamble();
  } 
return 0; }

@ The main program needs a few global variables in order to do its work.

@<Glob...@>=
int @!k, @!m, @!n, @!p, @!q; /*general purpose registers*/ 

@ A \.{DVI}-reading program that reads the postamble first need not look at the
preamble; but \.{DVItype} looks at the preamble in order to do error
checking, and to display the introductory comment.

@<Process the preamble@>=
open_dvi_file();
p=get_byte(); /*fetch the first byte*/ 
if (p!=pre) bad_dvi("First byte isn't start of preamble!");
@.First byte isn't...@>
p=get_byte(); /*fetch the identification byte*/ 
if (p!=id_byte) 
  print_ln("identification in byte 1 should be %d!", id_byte);
@.identification...should be n@>
@<Compute the conversion factors@>;
p=get_byte(); /*fetch the length of the introductory comment*/ 
print("'");
while (p > 0) 
  {@+decr(p);print("%c",xchr[get_byte()]);
  } 
print_ln("'");
after_pre=cur_loc

@ The conversion factor |conv| is figured as follows: There are exactly
|n/(double)d| decimicrons per \.{DVI} unit, and 254000 decimicrons per inch,
and |resolution| pixels per inch. Then we have to adjust this
by the stated amount of magnification.

@<Compute the conversion factors@>=
numerator=signed_quad();denominator=signed_quad();
if (numerator <= 0) bad_dvi("numerator is %d", numerator);
@.numerator is wrong@>
if (denominator <= 0) bad_dvi("denominator is %d", denominator);
@.denominator is wrong@>
print_ln("numerator/denominator=%d/%d", numerator, denominator);
tfm_conv=(25400000.0/(double)numerator)*(denominator/(double)473628672)/(double)16.0;
conv=(numerator/(double)254000.0)*(resolution/(double)denominator);
mag=signed_quad();
if (new_mag > 0) mag=new_mag;
else if (mag <= 0) bad_dvi("magnification is %d", mag);
@.magnification is wrong@>
true_conv=conv;conv=true_conv*(mag/(double)1000.0);
print_ln("magnification=%d; %16.8f pixels per DVI unit", mag, conv)

@ The code shown here uses a convention that has proved to be useful:
If the starting page was specified as, e.g., `\.{1.*.-5}', then
all page numbers in the file are displayed by showing the values of
counts 0, 1, and~2, separated by dots. Such numbers can, for example,
be displayed on the console of a printer when it is working on that
page.

@<Translate up to...@>=
{@+while (max_pages > 0) 
  {@+decr(max_pages);
  print_ln(" ");print("%d: beginning of page ",cur_loc-45);
  for (k=0; k<=start_vals; k++) 
    {@+print("%d",count[k]);
    if (k < start_vals) print(".");
    else print_ln(" ");
    } 
  if (!do_page()) bad_dvi("page ended unexpectedly");
@.page ended unexpectedly@>
  scan_bop();
  if (in_postamble) break;
  } 
}

@*System-dependent changes.
This section should be replaced, if necessary, by changes to the program
that are necessary to make \.{DVItype} work at a particular installation.
It is usually best to design your change file so that all changes to
previous sections preserve the section numbering; then everybody's version
will be consistent with the printed program. More extensive changes,
which introduce new sections, can be inserted here; then only the index
itself will get a new section number.
@^system dependencies@>

@*Index.
Pointers to error messages appear here together with the section numbers
where each ident\-i\-fier is used.

@ Appendix: Replacement of the string pool file.
@d str_0_255 	"^^@@^^A^^B^^C^^D^^E^^F^^G^^H^^I^^J^^K^^L^^M^^N^^O"@/
	"^^P^^Q^^R^^S^^T^^U^^V^^W^^X^^Y^^Z^^[^^\\^^]^^^^^_"@/
	" !\"#$%&'()*+,-./"@/
	"0123456789:;<=>?"@/
	"@@ABCDEFGHIJKLMNO"@/
	"PQRSTUVWXYZ[\\]^_"@/
	"`abcdefghijklmno"@/
	"pqrstuvwxyz{|}~^^?"@/
	"^^80^^81^^82^^83^^84^^85^^86^^87^^88^^89^^8a^^8b^^8c^^8d^^8e^^8f"@/
	"^^90^^91^^92^^93^^94^^95^^96^^97^^98^^99^^9a^^9b^^9c^^9d^^9e^^9f"@/
	"^^a0^^a1^^a2^^a3^^a4^^a5^^a6^^a7^^a8^^a9^^aa^^ab^^ac^^ad^^ae^^af"@/
	"^^b0^^b1^^b2^^b3^^b4^^b5^^b6^^b7^^b8^^b9^^ba^^bb^^bc^^bd^^be^^bf"@/
	"^^c0^^c1^^c2^^c3^^c4^^c5^^c6^^c7^^c8^^c9^^ca^^cb^^cc^^cd^^ce^^cf"@/
	"^^d0^^d1^^d2^^d3^^d4^^d5^^d6^^d7^^d8^^d9^^da^^db^^dc^^dd^^de^^df"@/
	"^^e0^^e1^^e2^^e3^^e4^^e5^^e6^^e7^^e8^^e9^^ea^^eb^^ec^^ed^^ee^^ef"@/
	"^^f0^^f1^^f2^^f3^^f4^^f5^^f6^^f7^^f8^^f9^^fa^^fb^^fc^^fd^^fe^^ff"@/
@d str_start_0_255	0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45,@/
	48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93,@/
	96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,@/
	112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,@/
	128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,@/
	144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,@/
	160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,@/
	176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,@/
	194, 198, 202, 206, 210, 214, 218, 222, 226, 230, 234, 238, 242, 246, 250, 254,@/
	258, 262, 266, 270, 274, 278, 282, 286, 290, 294, 298, 302, 306, 310, 314, 318,@/
	322, 326, 330, 334, 338, 342, 346, 350, 354, 358, 362, 366, 370, 374, 378, 382,@/
	386, 390, 394, 398, 402, 406, 410, 414, 418, 422, 426, 430, 434, 438, 442, 446,@/
	450, 454, 458, 462, 466, 470, 474, 478, 482, 486, 490, 494, 498, 502, 506, 510,@/
	514, 518, 522, 526, 530, 534, 538, 542, 546, 550, 554, 558, 562, 566, 570, 574,@/
	578, 582, 586, 590, 594, 598, 602, 606, 610, 614, 618, 622, 626, 630, 634, 638,@/
	642, 646, 650, 654, 658, 662, 666, 670, 674, 678, 682, 686, 690, 694, 698, 702,@/
