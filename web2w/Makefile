all:
	ctangle web2w web2w-dvitype
	patch -so web-dvitype.l web.l web-dvitype.patch
	flex -o web.lex.c web-dvitype.l
	patch -so pascal-dvitype.y pascal.y pascal-dvitype.patch
	bison --warnings=none -d -v pascal-dvitype.y
	gcc -o web2w web2w.c web.lex.c pascal-dvitype.tab.c
	cp dvitype.web dvitype-web2w.web
	@sed -i '/@d four_cases/,+4s/+/,/g' dvitype-web2w.web
	@sed -i 's/|packed file of 0..255|//' dvitype-web2w.web
	./web2w -o cdvitype.w dvitype-web2w.web
	@sed -i '/@d four_cases/,+4s/: case/+/g' cdvitype.w
	patch -s cdvitype.w cdvitype.patch
