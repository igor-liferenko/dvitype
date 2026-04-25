@x
{ reset(dvi_file, dvi_name);
@y
{ reset(dvi_file, dvi_name); assert(dvi_file.f!=NULL); assert(!ferror(dvi_file.f));
@z

@x
{ reset(tfm_file, cur_name);
@y
{ reset(tfm_file, cur_name); assert(tfm_file.f!=NULL); assert(!ferror(tfm_file.f));
@z

@x
uint8_t r; /*index into |cur_name|*/
@y
int r; /*index into |cur_name|*/
@z

@x
@d default_directory_name "TeXfonts:" /*change this to the correct name*/
@y
@d default_directory_name "TeXfonts/" /*change this to the correct name*/
@z

@x
      cur_name[r]=xchr[names[k]-040];
@y
      cur_name[r]=xchr[names[k]];
@z

@x
cur_name[r+1]= '.' ;cur_name[r+2]= 'T' ;cur_name[r+3]= 'F' ;cur_name[r+4]= 'M'
@y
cur_name[r+1]= '.' ;cur_name[r+2]= 't' ;cur_name[r+3]= 'f' ;cur_name[r+4]= 'm'
@z
