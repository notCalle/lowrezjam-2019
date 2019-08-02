SOURCES += src/main.lua
SOURCES += src/conf.lua
SOURCES += src/fonts.lua
SOURCES += src/fonts.png
SOURCES += src/sprites.lua
SOURCES += src/sprites.png

.PHONY: run
run:	$(SOURCES)
	amulet src/main.lua

.PHONY: export
export: $(SOURCES) pkg
	amulet export -windows -mac -linux -html -r -d pkg src

src/fonts.lua src/fonts.png: fonts/*.ttf
	amulet pack -mono -png fonts.png -lua fonts.lua \
	fonts/little-conquest.ttf@8
	mv fonts.lua fonts.png src/

src/sprites.lua src/sprites.png: sprites/*.png
	amulet pack -png sprites.png -lua sprites.lua sprites/*.png
	mv sprites.lua sprites.png src/

pkg:
	mkdir pkg
