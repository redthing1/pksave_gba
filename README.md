
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

---

<br>

## Features

Provides a modified version of **[LibSpec]** <br>
and a command line tool - `pksave` - for <br>
advanced editing of Gen 3 save files.

*Yes, this is the first save editor for ultra shiny gold sigma!*

<br>

---

<br>

### PKSave Features

+ Save / Restore Pokemon / Items to Files

+ Trade Pokemon Across Save Files 

  *You can even trade from **FRLG** to* ***SGS***

+ Make Pokemon Shiny

+ Verify Save Files 

  *Protect against corruption,* <br>
  *specific the dreaded* ***BAD EGG***

+ Dump Save Info

+ Modify Money

+ Edit IVs

***PKSave*** *is an advanced tool, and is thus command line only.* <br> 
*There are no plans nor will there ever be for a GUI.*

<br>

---

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

*Enjoy! there is built in cli help, just pass `-h`*

<br>

---

<br>

## Credits

+ **Chase** for `libspec`
+ **Alex Sanchez** for `Shiny Gold Sigma`

<!----------------------------------------------------------------------------->

[LibSpec]: https://github.com/Chase-san/libspec
