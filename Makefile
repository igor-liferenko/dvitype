all:
	make -C web2w
	cp web2w/cdvitype.w dvitype.w
	/bin/ctangle dvitype
	gcc dvitype.c -o dvitype -lm
