all:
	make -C web2w
	cp web2w/cdvitype.w dvitype.w
	ctangle dvitype
	gcc dvitype.c -o dvitype -lm
	cweave -f dvitype && pdftex dvitype
