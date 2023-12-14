all:
	make -C web2w
	cp web2w/cdvitype.w dvitype.w
	tie -c dvitype.ch dvitype.w path.ch arg.ch >/dev/null
	ctangle dvitype dvitype
	@sed -i '/stdlib.h/a #ifdef _SYS_SYSMACROS_H\n#undef major\n#undef minor\n#endif' dvitype.c
	gcc dvitype.c -o dvitype -lm
