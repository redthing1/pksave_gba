
# PKSave GBA

*Advanced Gen 3 Save / Editing / Research Tools.*

## features

supports games:
+ fire red/leaf green (FRLG)
+ emerald (E)
+ ultra shiny gold sigma (SGS) (`v1.3.9`)
+ halcyon emerald (`v0.2b0`)
+ glazed (`v9.0`)


provides a modified version of [libspec](https://github.com/Chase-san/libspec) and a command line tool, `pksave`, for advanced editing of Gen 3 save files.

yes, this is the first save editor for ultra shiny gold sigma!

pksave features:
+ dump save info
+ modify money
+ verify save files (protect against corruption, specific the dreaded **BAD EGG**
+ trade pokemon across save files (you can even trade from FRLG to SGS)
+ edit IVs
+ make pokemon shiny
+ save and restore pokemon and items to files

pksave is an advanced tool, and is thus command line only. there are no plans nor will there ever be for a gui.

## usage
+ install D compiler and DUB
+ go to `libspec`, run `make`, then copy/link the output static library to `pksave`
+ build `pksave` with `dub build`
+ enjoy! there is built in cli help, just pass `-h`

## credits
+ chase for libspec
+ alex sanchez for shiny gold sigma
