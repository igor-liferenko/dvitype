all:
	make -C web2w
	cp web2w/cdvitype.w dvitype.w
	tie -c dvitype.ch dvitype.w fixnewlines.ch path.ch args.ch >/dev/null
	ctangle dvitype dvitype
	gcc dvitype.c -o dvitype -lm
	cweave -f dvitype && pdftex -interaction batchmode dvitype >/dev/null && tex dvitype >/dev/null
