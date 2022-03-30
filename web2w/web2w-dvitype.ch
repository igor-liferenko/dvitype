@x
#include "pascal.tab.h"
@y
#include "pascal-dvitype.tab.h"
@z

@x
  @<generate string pool initializations@>@;
@y
@z

@x
predefine("true",PCONSTID,1);
@y
predefine("true",PCONSTID,1);
predefine("set_pos",PPROCID,0);
predefine("cur_pos",PFUNCID,0);
predefine("trunc",PFUNCID,0);
@z
