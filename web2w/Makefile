all:
	ctangle web2w web2w-dvitype
	patch -so web-dvitype.l web.l web-dvitype.patch
	flex -o web.lex.c web-dvitype.l
	patch -so pascal-dvitype.y pascal.y pascal-dvitype.patch
	bison --warnings=none -d -v pascal-dvitype.y
	gcc -o web2w web2w.c web.lex.c pascal-dvitype.tab.c
	cp dvitype.web dvitype-web2w.web
	@sed -i '821s/file/File/' dvitype-web2w.web
	@sed -i '1752,1756s/+/,/g' dvitype-web2w.web
	./web2w -o cdvitype.w dvitype-web2w.web
	@sed -i '813s/File/file/' cdvitype.w
	@sed -i '1743,1747s/: case/+/g' cdvitype.w
	patch -s cdvitype.w cdvitype.patch
