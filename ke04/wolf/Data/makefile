
WOLFGFX = wolfgfx

all: datObjs.c datWalls.c datMaps.c datNpcs.c

datNpcs.c: npcs.txt
	$(WOLFGFX) -gfx npcs.txt -cpp datNpcs -alpha -compress

datMaps.c: maps.txt
	$(WOLFGFX) -map maps.txt -cpp datMaps

datWalls.c: walls.txt
	$(WOLFGFX) -gfx walls.txt -cpp datWalls

datObjs.c: objs.txt
	$(WOLFGFX) -gfx objs.txt -cpp datObjs -alpha -compress

clean:
	rm -f datNpcs.c datNpcs.h datMaps.c datMaps.h datObjs.c datObjs.h datWalls.c datWalls.h
