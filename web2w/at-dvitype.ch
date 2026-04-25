@x
@<convert |t| from \WEB/ to \cweb/@>=
@y
@<convert |t| from \WEB/ to \cweb/@>=
case ATSLASH:
  t=t->next;
  break;
@z

@x
  if (!following_directive(t)) wputs("@@+");
@y
  if (!following_directive(t)) wputs(" ");
@z

@x
  if (t->previous->tag==ATEX) wputs("@@!");
@y
@z

@x
     wputs("enum {@@+"), wid(t), wput('=');
     t=wprint_to(t->link->next,t->link->link);
     wputs("@@+};");
@y
     wputs("enum { "), wid(t), wput('=');
     t=wprint_to(t->link->next,t->link->link);
     wputs(" };");
@z

@x
      &&t->previous->tag!=PEND) wputs("@@;");
  if (!dead_end(t->up,t->lineno)) wprint("@@+break;");
@y
      &&t->previous->tag!=PEND) wputs(" ");
  if (!dead_end(t->up,t->lineno)) wprint("break;");
@z

@x
        winsert_after(t,ATSEMICOLON,"@@;");
@y
        winsert_after(t,ATSEMICOLON," ");
@z
