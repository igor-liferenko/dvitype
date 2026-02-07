all:
	make -C web2w
	cp web2w/cdvitype.w dvitype.w
	tie -c dvitype.ch dvitype.w path.ch arg.ch undef.ch >/dev/null
	ctangle dvitype dvitype
	gcc dvitype.c -o dvitype -lm
