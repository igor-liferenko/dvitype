Changes are done to §83, §96, §99.
If you do `texdoc dvitype', and search for "define font", you will see that
it is used in 4 places. §86 is when page is processed. All is OK here. §106
is postamble handling. All is OK here as well. The problematic places
are in §96 and §99.
Please notice, that in §96 and §106 "print_ln (' ');" is used. This is
inconsistent with §99.
Finally, notice that in the procedure `define_font' (in §62) the
"print_ln (' ');" is done automatically.

§99 concerns output of GFtoDVI, where font definitions are before first bop

§96 concerns skipping pages, e.g., when `-page-start 2' is used

§83 - `eop' appears when out_mode != 0, so newline must be added after `eop' only
when `eop' is printed - to avoid spurious blank line

§83
@x
case eop: {@+major("eop");
  if (s!=0) error("stack not empty at end of page (level %d)!", s);
@.stack not empty...@>
  print_ln(" ");return true;
@y
case eop: {@+major("eop");
  if (s!=0) error("stack not empty at end of page (level %d)!", s);
@.stack not empty...@>
  if (out_mode!=errors_only) print_ln(" ");return true;
@z

§96
@x
@ @<Skip until finding |eop|@>=
@/do@+{if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
  k=get_byte();
  p=first_par(k);
  switch (k) {
  case set_rule: case put_rule: down_the_drain=signed_quad();@+break;
  four_cases(fnt_def1): {@+define_font(p);
    print_ln(" ");
@y
@ @<Skip until finding |eop|@>=
@/do@+{if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
  k=get_byte();
  p=first_par(k);
  switch (k) {
  case set_rule: case put_rule: down_the_drain=signed_quad();@+break;
  four_cases(fnt_def1): {@+define_font(p);
    if (out_mode!=errors_only) print_ln(" ");
@z

§99
@x
void scan_bop(void)
{@+uint8_t k; /*command code*/
@/do@+{if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
  k=get_byte();
  if ((k >= fnt_def1)&&(k < fnt_def1+4))
    {@+define_font(first_par(k));k=nop;
@y
void scan_bop(void)
{@+uint8_t k; /*command code*/
@/do@+{if (eof(dvi_file)) bad_dvi("the file ended prematurely");
@.the file ended prematurely@>
  k=get_byte();
  if ((k >= fnt_def1)&&(k < fnt_def1+4))
    {@+define_font(first_par(k));if (out_mode!=errors_only) print_ln(" ");k=nop;
@z
