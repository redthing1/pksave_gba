# pksave_gba

advanced gen iii save editing research tools. specifically, fire red/leaf green and ultra shiny gold sigma.

## features

supports games:
+ fire red/leaf green (FRLG)
+ ultra shiny gold sigma (SGS) (tested on `v1.3.8` rom)

provides a modified version of [libspec](https://github.com/Chase-san/libspec) and a command line tool, `pksave`, for advanced editing of FRLG/SGS save files.

yes, this is the first save editor for ultra shiny gold sigma!

pksave features:
+ dump save info
+ modify money
+ verify save files (protect against corruption, specific the dreaded **BAD EGG**
+ trade pokemon across save files (you can even trade from FRLG to SGS)

pksave is an advanced tool, and is thus command line only. there are no plans nor will there ever be for a gui.

## usage
+ install D compiler and DUB
+ go to `libspec`, run `make`, then copy/link the output static library to `pksave`
+ build `pksave` with `dub build`
+ enjoy! there is built in cli help, just pass `-h`

## credits
+ chase for libspec
+ alex sanchez for shiny gold sigma
