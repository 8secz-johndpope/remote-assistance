%.usdz: %.dae
	@echo "\n**** Converting: $< -> $@ *****\n"
	../utils/COLLADA2GLTF $< $*.gltf
	../utils/usdzconvert $*.gltf $@
	rm $*.gltf

default: $(patsubst %.dae,%.usdz,$(shell ls *.dae))

clean:
	rm -f *.gltf *.usdz
