module pokerom;

import std.file;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm.comparison;
import std.bitmanip;
import std.range;
import std.sumtype;

import util;

struct FireRedURom {

}

struct LeafGreanURom {

}

struct ShinyGoldSigma138Rom {

}

struct EmeraldURom {

}

struct EmeraldHalcyonRom {

}

struct UnknownGen3Rom {

}

alias PkmnRomType = SumType!(UnknownGen3Rom, FireRedURom, LeafGreanURom, ShinyGoldSigma138Rom, EmeraldURom, EmeraldHalcyonRom);

enum int SPECIES_DATA_ENTRY_LENGTH = 28;
enum int ITEM_TABLE_ENTRY_LENGTH = 44;

uint species_data_offset(PkmnRomType rom_type) {
    // this refers to the location of the "gBaseStats" symbol, but pointing to index 1 of that array

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 0x2547A0,
        (LeafGreanURom _) => 0x25477C,
        (ShinyGoldSigma138Rom _) => 0xA6BCEC,
        (EmeraldURom _) => 0x3203E8,
        (EmeraldHalcyonRom _) => 0x380A10 + 0x24,
    );
}

uint item_table_offset(PkmnRomType rom_type) {
    // this refers to the location of the "gItems" symbol, but pointing to index 1 of that array

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 0x3DB054,
        (LeafGreanURom _) => 0x3DAE64,
        (ShinyGoldSigma138Rom _) => 0x3DB054,
        (EmeraldURom _) => 0x5839CC,
        (EmeraldHalcyonRom _) => 0x63CACC + 0x2C,
    );
}

uint species_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 412,
        (LeafGreanURom _) => 412,
        (ShinyGoldSigma138Rom _) => 923,
        (EmeraldURom _) => 412,
        (EmeraldHalcyonRom _) => 1024,
    );
}

uint item_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 375,
        (LeafGreanURom _) => 375,
        (ShinyGoldSigma138Rom _) => 375,
        (EmeraldURom _) => 375,
        (EmeraldHalcyonRom _) => 960,
    );
}