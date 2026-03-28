all:
	make -C web2w
	tie -m dvitype.w web2w/cdvitype.w web2w/cdvitype.ch >/dev/null
	tie -c dvitype.ch dvitype.w constants.ch path.ch arg.ch undef.ch abort.ch >/dev/null
	ctangle dvitype dvitype
	gcc dvitype.c -o dvitype -lm
