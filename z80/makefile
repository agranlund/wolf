
CC = tools/wla-gb
CFLAGS = -oxi
LD = tools/wlalink
LDFLAGS = -dviS

SFILES = sound.s gbt_player.s gbt_player_bank1.s gfx.s sys.s main.s intro.s screens.o game.s
IFILES = defines.i cgb_hardware.i
OFILES = $(SFILES:.s=.o)
MODFILES = music/mus_menu.mod music/mus_map1.mod music/mus_map2.mod music/mus_map3.mod music/mus_map4.mod music/mus_map9.mod music/mus_map0.mod


NAME = wolf
BINOUT = wolf.gb

all: $(MODFILES) $(SFILES) $(BINOUT)

$(BINOUT): $(OFILES) $(MODFILES) makefile
	$(LD) $(LDFLAGS) linkfile $(BINOUT)

sound.o: sound.s $(IFILES) $(MODFILES) sound/hammered_wolf.sav makefile
	make mods
	cp sound/hammered_wolf.sav sound/fxbank.bin
	truncate -s 16K sound/fxbank.bin
	$(CC) $(CFLAGS) $<

.s.o: $(IFILES) makefile
	$(CC) $(CFLAGS) $<

mods: $(MODFILES)
	#cd music && ../tools/mod2gbt ../$< $(notdir $(<:.mod=))
	cd music && ../tools/mod2gbt mus_menu.mod mus_menu
	cd music && ../tools/mod2gbt mus_map1.mod mus_map1	
	cd music && ../tools/mod2gbt mus_map2.mod mus_map2
	cd music && ../tools/mod2gbt mus_map3.mod mus_map3
	cd music && ../tools/mod2gbt mus_map4.mod mus_map4
	cd music && ../tools/mod2gbt mus_map4.mod mus_map9
	cd music && ../tools/mod2gbt mus_map0.mod mus_map0

clean:
	rm -f $(MODFILES:.mod=.s) $(MODFILES:.mod=.lst) $(OFILES) $(OFILES:.o=.lst) *~ $(BINOUT) $(NAME).sym

run: $(BINOUT)
	open tools/bgb.app

flash: $(BINOUT)
	tools/romflasher -write $(BINOUT)