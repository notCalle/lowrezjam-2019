SOURCES += src/main.lua
SOURCES += src/conf.lua
SOURCES += src/fonts.lua
SOURCES += src/fonts.png

.PHONY: export
export: $(SOURCES) pkg
	amulet export -windows -mac -linux -html -r -d pkg src

src/fonts.lua src/fonts.png: fonts/little-conquest.ttf
	amulet pack -mono -png src/fonts.png -lua src/fonts.lua \
	fonts/little-conquest.ttf@8

pkg:
	mkdir pkg
