@x
uint8_t @!r; /*index into |cur_name|*/
@y
int       r; /*index into |cur_name|*/
@z

@x
@d default_directory_name	"TeXfonts:" /*change this to the correct name*/
@y
@d default_directory_name	"TeXfonts/" /*change this to the correct name*/
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
