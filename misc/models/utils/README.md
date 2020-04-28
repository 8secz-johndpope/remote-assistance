# 3D Model Converter

Utils are OSX only.  Windows or linux are not supported.

## Command usage

```bash
cd models
./utils/COLLDATA2GLTF models/modelname.dae models/modelname.gltf
.//utils/usdzconvert models/modelname.gltf models/modelname.usdz -metersPerUnit 3.28
```

## usdzconvert
Converts to `usdz` format.  The most important command switch is probably `-metersPerUnit`.

Supported input file formats:
`OBJ/glTF(.gltf/glb)/FBX/Alembic(.abc)/USD(.usd/usda/usdc/usdz) files`

Can be downloaded here:

https://developer.apple.com/download/more/?=USDPython

<details><summary>usdzconvert Help</summary>
<p>
  
### usdzconver Help Summary
  
```
usdzconvert 0.64
usage: usdzconvert inputFile [outputFile]
                   [-h] [-f file] [-v]
                   [-path path[+path2[...]]]
                   [-url url]
                   [-copyright copyright]
                   [-copytextures]
                   [-metersPerUnit value]
                   [-loop]
                   [-no-loop]
                   [-iOS12]
                   [-m materialName]
                   [-texCoordSet name]
                   [-wrapS mode]
                   [-wrapT mode]
                   [-diffuseColor           r,g,b]
                   [-diffuseColor           <file> fr,fg,fb]
                   [-normal                 x,y,z]
                   [-normal                 <file> fx,fy,fz
                   [-emissiveColor          r,g,b]
                   [-emissiveColor          <file> fr,fb,fg]
                   [-metallic               c]
                   [-metallic               ch <file> fc]
                   [-roughness              c]
                   [-roughness              ch <file> fc]
                   [-occlusion              c]
                   [-occlusion              ch <file> fc]
                   [-opacity                c]
                   [-opacity                ch <file> fc]
                   [-clearcoat              c]
                   [-clearcoat              ch <file> fc]
                   [-clearcoatRoughness     c]
                   [-clearcoatRoughness     ch <file> fc]

Converts 3D model file to usd/usda/usdc/usdz.

positional argument:
  inputFile             Input file: OBJ/glTF(.gltf/glb)/FBX/Alembic(.abc)/USD(.usd/usda/usdc/usdz) files.

optional arguments:
  outputFile            Output .usd/usda/usdc/usdz files.
  -h, --help            Show this help message and exit.
  -f <file>             Read arguments from <file>
  -v                    Verbose output.
  -path <path[+path2[...]]>
                        Add search paths to find textures
  -url <url>            Add URL metadata
  -copyright "copyright message"
                        Add copyright metadata
  -copytextures         Copy texture files (for .usd/usda/usdc) workflows
  -metersPerUnit value  Set metersPerUnit attribute with float value
  -loop                 Set animation loop flag to 1
  -no-loop              Set animation loop flag to 0
  -m materialName       Subsequent material arguments apply to this material.
                        If no material is present in input file, a material of
                        this name will be generated.
  -iOS12                Make output file compatible with iOS 12 frameworks
  -texCoordSet name     The name of the texture coordinates to use for current
                        material. Default texture coordinate set is "st".
  -wrapS mode           Texture wrap mode for texture S-coordinate.
                        mode can be: black, clamp, repeat, mirror, or useMetadata (default)
  -wrapT mode           Texture wrap mode for texture T-coordinate.
                        mode can be: black, clamp, repeat, mirror, or useMetadata (default)
                        
  -diffuseColor r,g,b   Set diffuseColor to constant color r,g,b with values in
                        the range [0 .. 1]
  -diffuseColor <file> fr,fg,fb
                        Use <file> as texture for diffuseColor.
                        fr,fg,fb: (optional) constant fallback color, with
                                  values in the range [0..1].
                        
  -normal x,y,z         Set normal to constant value x,y,z in tangent space
                        [(-1, -1, -1), (1, 1, 1)].
  -normal <file> fx,fy,fz
                        Use <file> as texture for normal.
                        fx,fy,fz: (optional) constant fallback value, with
                                  values in the range [-1..1].
                        
  -emissiveColor r,g,b  Set emissiveColor to constant color r,g,b with values in
                        the range [0..1]
  -emissiveColor <file> fr,fg,fb
                        Use <file> as texture for emissiveColor.
                        fr,fg,fb: (optional) constant fallback color, with
                                  values in the range [0..1].
                        
  -metallic c           Set metallic to constant c, in the range [0..1]
  -metallic ch <file> fc
                        Use <file> as texture for metallic.
                        ch: (optional) texture color channel (r, g, b or a).
                        fc: (optional) fallback constant in the range [0..1]
                        
  -roughness c          Set roughness to constant c, in the range [0..1]
  -roughness ch <file> fc
                        Use <file> as texture for roughness.
                        ch: (optional) texture color channel (r, g, b or a).
                        fc: (optional) fallback constant in the range [0..1]
                        
  -occlusion c          Set occlusion to constant c, in the range [0..1]
  -occlusion ch <file> fc
                        Use <file> as texture for occlusion.
                        ch: (optional) texture color channel (r, g, b or a).
                        fc: (optional) fallback constant in the range [0..1]
                        
  -opacity c            Set opacity to constant c, in the range [0..1]
  -opacity ch <file> fc Use <file> as texture for opacity.
                        ch: (optional) texture color channel (r, g, b or a).
                        fc: (optional) fallback constant in the range [0..1]
  -clearcoat c          Set clearcoat to constant c, in the range [0..1]
  -clearcoat ch <file> fc
                        Use <file> as texture for clearcoat.
                        ch: (optional) texture color channel (r, g, b or a).
                        fc: (optional) fallback constant in the range [0..1]
  -clearcoatRoughness c Set clearcoat roughness to constant c, in the range [0..1]
  -clearcoatRoughness ch <file> fc
                        Use <file> as texture for clearcoat roughness.
                        ch: (optional) texture color channel (r, g, b or a).
                        fc: (optional) fallback constant in the range [0..1]

examples:
    usdzconvert chicken.gltf

    usdzconvert cube.obj -diffuseColor albedo.png

    usdzconvert cube.obj -diffuseColor albedo.png -opacity a albedo.png

    usdzconvert vase.obj -m bodyMaterial -diffuseColor body.png -opacity a body.png -metallic r metallicRoughness.png -roughness g metallicRoughness.png -normal normal.png -occlusion ao.png

    usdzconvert subset.obj -m leftMaterial -diffuseColor left.png -m rightMaterial -diffuseColor right.png
```
</p>
</details>


## COLLADA2GLTF

Compiled from here:

https://github.com/KhronosGroup/COLLADA2GLTF

<details><summary>COLLADA2GLTF help</summary>
<p>

#### COLLADA2GLTF Help Summary

```
COLLADA2GLTF
Usage:
  ./COLLADA2GLTF input.dae output.gltf [options]

Options:
  -i, --input	path of the input COLLADA file	 [0] [required] [string]
  -o, --output	path of the output glTF file	 [1] [string]
  -b, --binary	output binary glTF	 [bool] [default: false]
  --basePath	resolve external uris using this as the reference path	 [string]
  -d, --dracoCompression	compress the geometries using Draco compression extension	 [bool] [default: false]
  --doubleSided	Force all materials to be double sided. When this value is true, back-face culling is disabled and double sided lighting is enabled	 [bool] [default: false]
  -g, --glsl	output materials with glsl shaders using the KHR_technique_webgl extension	 [bool] [default: false]
  --lockOcclusionMetallicRoughness	set metallicRoughnessTexture to be the same as the occlusionTexture in materials where an ambient texture is defined	 [bool] [default: false]
  -m, --materialsCommon	output materials using the KHR_materials_common extension	 [bool] [default: false]
  --metallicRoughnessTextures	paths to images to use as the PBR metallicRoughness textures	 [vec<string>]
  -p, --preserveUnusedSemantics	should unused semantics be preserved. When this value is true, all mesh data is left intact even if it's not used.	 [bool] [default: false]
  --qc	color quantization bits used in Draco compression extension	 [int]
  --qj	joint indices and weights quantization bits used in Draco compression extension	 [int]
  --qn	normal quantization bits used in Draco compression extension	 [int]
  --qp	position quantization bits used in Draco compression extension	 [int]
  --qt	texture coordinate quantization bits used in Draco compression extension	 [int]
  -s, --separate	output separate binary buffer, shaders, and textures	 [bool] [default: false]
  --specularGlossiness	output PBR materials with the KHR_materials_pbrSpecularGlossiness extension	 [bool] [default: false]
  -t, --separateTextures	output images separately, but embed buffers and shaders	 [bool] [default: false]
  -v, --version	glTF version to output (e.g. '1.0', '2.0')	 [string]
```
</p>
</details>
