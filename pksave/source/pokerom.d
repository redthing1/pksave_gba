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

alias PkmnRomType = SumType!(
    UnknownGen3Rom,
    FireRedURom,
    LeafGreanURom,
    ShinyGoldSigma138Rom,
    EmeraldURom,
    EmeraldHalcyonRom
);

/** 
 * size of BaseStats struct in bytes
 */
uint species_basestats_entry_length(PkmnRomType rom_type) {
    enum int FRLG_SPECIES_BASESTATS_ENTRY_LENGTH = 0x1C; // 28
    enum int RSE_SPECIES_BASESTATS_ENTRY_LENGTH = 0x1C; // 28
    enum int HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH = 0x24;

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (LeafGreanURom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (ShinyGoldSigma138Rom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldURom _) => RSE_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldHalcyonRom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
    );
}

/** 
 * size of Item struct in bytes
 */
uint item_table_entry_length(PkmnRomType rom_type) {
    enum int FRLG_ITEM_TABLE_ENTRY_LENGTH = 0x2C; // 44
    enum int RSE_ITEM_TABLE_ENTRY_LENGTH = 0x2C; // 44
    enum int HALCYON_ITEM_TABLE_ENTRY_LENGTH = 0x2C;

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (LeafGreanURom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (ShinyGoldSigma138Rom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldURom _) => RSE_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldHalcyonRom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
    );
}

/** 
 * address of "gBaseStats" symbol
 */
uint species_basestats_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 0x2547A0 - rom_type.species_basestats_entry_length,
        (LeafGreanURom _) => 0x25477C - rom_type.species_basestats_entry_length,
        (ShinyGoldSigma138Rom _) => 0xA6BCEC - rom_type.species_basestats_entry_length,
        (EmeraldURom _) => 0x3203E8 - rom_type.species_basestats_entry_length,
        (EmeraldHalcyonRom _) => 0x380A10,
    );
}

/** 
 * address of "gItems" symbol
 */
uint item_table_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 0x3DB054 - rom_type.item_table_entry_length,
        (LeafGreanURom _) => 0x3DAE64- rom_type.item_table_entry_length,
        (ShinyGoldSigma138Rom _) => 0x3DB054- rom_type.item_table_entry_length,
        (EmeraldURom _) => 0x5839CC- rom_type.item_table_entry_length,
        (EmeraldHalcyonRom _) => 0x63CACC,
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
