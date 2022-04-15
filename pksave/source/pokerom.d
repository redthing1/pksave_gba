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

mixin(gen_rom_types!("UnknownGen3")); // Unknown Gen 3 Rom
mixin(gen_rom_types!("FireRedU")); // Pokemon Fire Red (U)
mixin(gen_rom_types!("LeafGreenU")); // Pokemon Leaf Green (U)
mixin(gen_rom_types!("EmeraldU")); // Pokemon Emerald (U)
mixin(gen_rom_types!("ShinyGoldSigma139")); // Pokemon Shiny Gold Sigma v1.3.9
mixin(gen_rom_types!("EmeraldHalcyon")); // Pokemon Halcyon Emerald v0.4b
mixin(gen_rom_types!("Glazed90")); // Pokemon Glazed v0.9

template gen_rom_types(string rom_name) {
    import std.string: format;
    const char[] gen_rom_types = format(`
        struct %sRom { }
    `, rom_name);
}

alias PkmnRomType = SumType!(
    UnknownGen3Rom,
    FireRedURom,
    LeafGreenURom,
    ShinyGoldSigma139Rom,
    EmeraldURom,
    EmeraldHalcyonRom,
    Glazed90Rom
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
        (LeafGreenURom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (ShinyGoldSigma139Rom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldURom _) => RSE_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldHalcyonRom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
        (Glazed90Rom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
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
        (LeafGreenURom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (ShinyGoldSigma139Rom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldURom _) => RSE_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldHalcyonRom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
        (Glazed90Rom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
    );
}

/** 
 * size of species name string in bytes
 */
uint species_names_entry_length(PkmnRomType rom_type) {
    enum int FRLG_SPECIES_NAME_ENTRY_LENGTH = 10 + 1;

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (LeafGreenURom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (ShinyGoldSigma139Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (EmeraldURom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (EmeraldHalcyonRom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (Glazed90Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
    );
}

/** 
 * address of "gBaseStats" symbol
 * how to find:
 * search in binary for something resembling
 * 2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01 07 41 00 00 03 00 00  // BULBASAUR
 * then, subtract the species_basestats_entry_length to get the offset
 */
uint species_basestats_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 0x2547A0 - rom_type.species_basestats_entry_length,
        (LeafGreenURom _) => 0x25477C - rom_type.species_basestats_entry_length,
        (ShinyGoldSigma139Rom _) => 0xA6BCEC - rom_type.species_basestats_entry_length,
        (EmeraldURom _) => 0x3203E8 - rom_type.species_basestats_entry_length,
        (EmeraldHalcyonRom _) => 0x380A10,
        (Glazed90Rom _) => 0x03203E8 - rom_type.species_basestats_entry_length,
    );
}

/** 
 * address of "gSpeciesNames" symbol
 */
uint species_names_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x245EE0,
        (ShinyGoldSigma139Rom _) => 0xA68340,
        (EmeraldHalcyonRom _) => 0x36BF04,
        (Glazed90Rom _) => 0x03185C8,
        _ => 0,
    );
}

/** 
 * address of "gItems" symbol
 */
uint item_table_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 0x3DB054 - rom_type.item_table_entry_length,
        (LeafGreenURom _) => 0x3DAE64- rom_type.item_table_entry_length,
        (ShinyGoldSigma139Rom _) => 0x3DB054- rom_type.item_table_entry_length,
        (EmeraldURom _) => 0x5839CC- rom_type.item_table_entry_length,
        (EmeraldHalcyonRom _) => 0x63CACC,
        (Glazed90Rom _) => 0x031B6DB,
    );
}

uint species_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 412,
        (LeafGreenURom _) => 412,
        (ShinyGoldSigma139Rom _) => 923,
        (EmeraldURom _) => 412,
        (EmeraldHalcyonRom _) => 1024,
        (Glazed90Rom _) => 1024,
    );
}

uint item_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (UnknownGen3Rom _) => 0,
        (FireRedURom _) => 375,
        (LeafGreenURom _) => 375,
        (ShinyGoldSigma139Rom _) => 375,
        (EmeraldURom _) => 375,
        (EmeraldHalcyonRom _) => 960,
        (Glazed90Rom _) => 960,
    );
}
