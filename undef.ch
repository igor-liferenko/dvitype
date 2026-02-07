On some systems major and minor are defined in system headers.
When this is the case, compiler gives warnings that major and minor are redefined,
because they are defined in dvitype.

@x
@h
@y
#undef major
#undef minor
@h
@z
