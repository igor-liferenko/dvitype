@x
enum {@+@!name_length=50@+}; /*a file name shouldn't be longer than this*/
@y
enum {@+@!name_length=65@+}; /*a file name shouldn't be longer than this*/
@z

@x
@d default_directory_name	"TeXfonts/" /*change this to the correct name*/
@d default_directory_name_length	9 /*change this to the correct length*/
@y
@d default_directory_name      "/home/user/tex/TeXfonts/" /*change this to the correct name*/
@d default_directory_name_length       24 /*change this to the correct length*/
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
