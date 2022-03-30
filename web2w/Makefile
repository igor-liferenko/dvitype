all:
	ctangle web2w web2w-dvitype
	patch -so web-dvitype.l web.l web-dvitype.patch
	flex -o web.lex.c web-dvitype.l
	patch -so pascal-dvitype.y pascal.y pascal-dvitype.patch
	bison --warnings=none -d -v pascal-dvitype.y
	gcc -o web2w web2w.c web.lex.c pascal-dvitype.tab.c
	@sed '821s/file/File/;1752,1756s/+/,/g' dvitype.web >dvitype-web2w.web
	./web2w -o cdvitype.w dvitype-web2w.web
	patch -s cdvitype.w cdvitype.patch
	weave dvitype >/dev/null && sed -i 1s/webmac/pwebmac/ dvitype.tex && pdftex dvitype >/dev/null && tex dvitype >/dev/null
