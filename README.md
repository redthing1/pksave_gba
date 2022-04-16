
# PKSave GBA

*Advanced Gen 3 Save / Editing / Research Tools.*

<br>


## Supports Games

+ **Fire Red** / **Leaf Green** ( FRLG )
+ **Emerald** ( E )
+ **Ultra Shiny Gold Sigma** ( SGS ) 

  `v1.3.9`
  
+ **Halcyon Emerald** 

   `v0.2b0`
   
+ **Glazed**
 
  `v9.0`

<br>

## Features

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


<br>

## Usage

1. Install the **D compiler** and **DUB**

2. Navigate to `libspec`

3. Run 

  ```sh
  make
  ```
  
4. Copy / link the output - the static library - to `pksave`

5. Build `pksave` with:

  ```sh
  dub build
  ```

<br> 

*enjoy! there is built in cli help, just pass `-h`*

<br>

## Credits

+ **Chase** for `libspec`
+ **Alex Sanchez** for `Shiny Gold Sigma`
