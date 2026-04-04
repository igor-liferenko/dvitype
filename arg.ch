@x
@p void input_ln(void) /*inputs a line from the terminal*/
{@+uint8_t k;
update_terminal;reset(term_in,"TTY:");
if (eoln(term_in)) read_ln(term_in);
k=0;
while ((k < terminal_line_length)&&!eoln(term_in))
  {@+buffer[k]=xord[term_in.d];incr(k);get(term_in);
  }
buffer[k]=' ';
}
@y
@p
char **av;
void input_ln(void) /*inputs next argv*/
{
  int k = 0;
  while ((k < terminal_line_length) && (*av)[k] != 0)
    buffer[k] = (*av)[k], k++;
  buffer[k] = ' ';
  av++;
}
@z

@x
term_out.f=stdout; /*prepare the terminal for output*/
@y
term_out.f=fopen("/dev/null","w");
@z

@x
    goto label1;
@y
    fprintf(stderr, "Wrong out_mode\n"); exit(2);
@z

@x
    goto label2;
@y
    fprintf(stderr, "Wrong start_count\n"); exit(2);
@z

@x
    goto label3;
@y
    fprintf(stderr, "Wrong max_pages\n"); exit(2);
@z

@x
    goto label4;
@y
    fprintf(stderr, "Wrong resolution\n"); exit(2);
@z

@x
    goto label5;
@y
    fprintf(stderr, "Wrong new_mag\n"); exit(2);
@z

@x
@p int main(int argc, char **argv) { assert(argc==3);
@y
@p int main(int argc, char **argv) { assert(argc==8); av = argv + 3;
@z
