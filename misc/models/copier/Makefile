%.usdz: %.dae
	@echo "\n**** Converting: $< -> $@ *****\n"
	../utils/COLLADA2GLTF $< $*.gltf
	../utils/usdzconvert $*.gltf $@ -metersPerUnit 3.28
	rm $*.gltf

default: $(patsubst %.dae,%.usdz,$(shell ls *.dae))

clean:
	rm -f *.gltf *.usdz
