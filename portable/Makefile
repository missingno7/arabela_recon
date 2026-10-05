# Linux desktop: FPC 3.2.2+, SDL3 and SDL3_ttf development libraries installed.
# Windows users can use setup.ps1/build.ps1 without make or a global compiler.
FPC ?= fpc
OUT := ../build/portable
FLAGS := -B -Mobjfpc -Sh -O2 -gl -Fugame -Fuplatform -Fufrontend -FE$(OUT)

.PHONY: all test run
all:
	mkdir -p $(OUT)/units
	$(FPC) $(FLAGS) -FU$(OUT)/units arabela.lpr

test:
	mkdir -p $(OUT)/testunits
	$(FPC) $(FLAGS) -FU$(OUT)/testunits -dOVERENI_PORTU tests/chovani.pas
	cd $(OUT) && ./chovani && tail -1 RESULT.TXT | grep -Fx 'PASS actions 63'
	$(FPC) $(FLAGS) -FU$(OUT)/testunits tests/semena.pas
	cd $(OUT) && ./semena && echo '5aa9232c0632a33eac8ac08aed3bf62c257a28a3f7a0baf02226494c690295fa  SEED.BIN' | sha256sum -c -
	$(FPC) $(FLAGS) -FU$(OUT)/testunits tests/pruchod.pas
	cd $(OUT) && ./pruchod && cat walkthrough-results.txt
	$(FPC) $(FLAGS) -FU$(OUT)/testunits tests/skore.pas
	cd $(OUT) && ./skore && cat score-results.txt
	$(FPC) $(FLAGS) -FU$(OUT)/testunits -dOVERENI_OKNA arabela.lpr
	mkdir -p $(OUT)/smoke
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software $(OUT)/arabela --smoke $(OUT)/smoke --scores $(OUT)/smoke/ARABELA.SCO --seed 12345678 --walkthrough $(OUT)/walkthrough.txt
	cat $(OUT)/smoke/results.txt
	$(MAKE) all

run: all
	$(OUT)/arabela
