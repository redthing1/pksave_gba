
# info on gen 3 roms

## rom symbols

### species base stats
```
the "gBaseStats" symbol

bulbasaur (ID: 0x01) offset
data looks like:
2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01 07 41 00 00 03 00 00  // BULBASAUR
```

### items

```
the "gItems" symbol

masterball (ID: 0x01) offset
in FRLG, data looks like:
C7 BB CD CE BF CC 00 BC BB C6 C6 FF 00 00 01 00 00 00 00 00 CC 4E 3D 08 00 00 03 00 00 00 00 00 02 00 00 00 1D 1E 0A 08 00 00 00 00
in SGS, data looks like:
C7 D5 E7 E8 D9 E6 00 BC D5 E0 E0 FF 00 00 01 00 00 00 00 00 CC 4E 3D 08 00 00 03 00 68 05 46 08 02 00 00 00 1D 1E 0A 08 00 00 00 00
in Emerald Salt, data looks like:
C7 D5 E7 E8 D9 E6 00 ...

a good place to match: (+11)
FF 00 00 01 00 00 00
```
