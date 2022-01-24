all:
	tie -c web2w.ch web2w.w web2w-dvitype.ch web2w-stringpool.ch >/dev/null
	ctangle web2w web2w
	patch -o web-dvitype.l web.l web-dvitype.patch
	flex -o web.lex.c web-dvitype.l
	patch -o pascal-dvitype.y pascal.y pascal-dvitype.patch
	bison --warnings=none -d -v pascal-dvitype.y
	gcc -o web2w web2w.c web.lex.c pascal-dvitype.tab.c
	@tie -m dvitype-web2w.web dvitype.web dvitype.ch >/dev/null
	@sed -i '821s/file/File/;1752,1756s/+/,/g' dvitype-web2w.web
	./web2w -o cdvitype.w dvitype-web2w.web
	patch cdvitype.w cdvitype.patch
	patch cdvitype.w 0001-Wrap-long-lines-for-plain-CWEB-4.6-3.64c.patch
	weave dvitype && \
		sed -i '1s/input webmac/input pwebmac/' dvitype.tex && \
		pdftex dvitype
