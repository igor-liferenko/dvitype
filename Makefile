all:
	make -C web2w
	cp web2w/cdvitype.w dvitype.w
	tie -c dvitype.ch dvitype.w path.ch args.ch >/dev/null
	ctangle dvitype dvitype
	gcc dvitype.c -o dvitype -lm
	cweave -f dvitype
