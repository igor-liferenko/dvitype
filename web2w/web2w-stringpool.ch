@x
int sequenceno=0;
@y
int sequenceno=0,mk_stringpool=0;
@z

@x
  @<generate string pool initializations@>@;
@y
  if (mk_stringpool) @<generate string pool initializations@>@;
@z

@x
@<generate string pool initializations@>=
@y
@<generate string pool initializations@>={
@z

@x
  "\n@@ @@<|str_ptr| initialization@@>= "), wputi(k), wput('\n');@/
@y
  "\n@@ @@<|str_ptr| initialization@@>= "), wputi(k), wput('\n');@/
}
@z

@x
  "\t -l   \t redirect stderr to a log file\n"@/
@y
  "\t -l   \t redirect stderr to a log file\n"@/
  "\t -s   \t generate string pool interface\n"@/
@z

@x
        case 'l': mk_logfile=1; @+break;
@y
        case 'l': mk_logfile=1; @+break;
        case 's': mk_stringpool=1; @+break;
@z
