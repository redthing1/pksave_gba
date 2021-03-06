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
mixin(gen_rom_types!("EmeraldHalcyon021")); // Pokemon Halcyon Emerald v0.2.1
mixin(gen_rom_types!("EmeraldHalcyon022")); // Pokemon Halcyon Emerald v0.2.2
mixin(gen_rom_types!("EmeraldHalcyon023")); // Pokemon Halcyon Emerald v0.2.3
mixin(gen_rom_types!("Glazed90")); // Pokemon Glazed v0.9

template gen_rom_types(string rom_name) {
    import std.string: format;
    const char[] gen_rom_types = format(`
        struct %sRom {
            enum NAME = "%s";

            string toString() const {
                return NAME;
            }
        }
    `, rom_name, rom_name);
}

alias PkmnRomType = SumType!(
    UnknownGen3Rom,
    FireRedURom,
    LeafGreenURom,
    ShinyGoldSigma139Rom,
    EmeraldURom,
    EmeraldHalcyon021Rom,
    EmeraldHalcyon022Rom,
    EmeraldHalcyon023Rom,
    Glazed90Rom
);

PkmnRomType pkmn_rom_type(T)() {
    return cast(PkmnRomType) T();
}

bool rom_is(TCheck)(PkmnRomType rom) {
    enum check_type_name = TCheck.stringof;
    mixin(format(`
         return rom.match!(
            (%s _) => true,
            _ => false
        );
    `, check_type_name));
}

/** defines known sequences that we can search for to find symbols */
struct OffsetFinder {
    string name;
    int leading_offset; // how many bytes to skip before the start of the data
    ubyte[] match_sequence; // the sequence to match
    uint variant; // the variant of the pointed data
}

/** 
 * size of BaseStats struct in bytes
 */
uint species_basestats_entry_length(PkmnRomType rom_type) {
    enum int FRLG_SPECIES_BASESTATS_ENTRY_LENGTH = 0x1C; // 28
    enum int RSE_SPECIES_BASESTATS_ENTRY_LENGTH = 0x1C; // 28
    enum int HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH = 0x24;

    return rom_type.match!(
        (FireRedURom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (LeafGreenURom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (ShinyGoldSigma139Rom _) => FRLG_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldURom _) => RSE_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldHalcyon021Rom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldHalcyon022Rom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
        (EmeraldHalcyon023Rom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
        (Glazed90Rom _) => HALCYON_SPECIES_BASESTATS_ENTRY_LENGTH,
        _ => RSE_SPECIES_BASESTATS_ENTRY_LENGTH  // default to RSE
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
        (FireRedURom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (LeafGreenURom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (ShinyGoldSigma139Rom _) => FRLG_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldURom _) => RSE_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldHalcyon021Rom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldHalcyon022Rom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
        (EmeraldHalcyon023Rom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
        (Glazed90Rom _) => HALCYON_ITEM_TABLE_ENTRY_LENGTH,
        _ => RSE_ITEM_TABLE_ENTRY_LENGTH  // default to RSE
    );
}

/** 
 * size of species name string in bytes
 */
uint species_names_entry_length(PkmnRomType rom_type) {
    enum int FRLG_SPECIES_NAME_ENTRY_LENGTH = 10 + 1;

    return rom_type.match!(
        (FireRedURom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (LeafGreenURom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (ShinyGoldSigma139Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (EmeraldURom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (EmeraldHalcyon021Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (EmeraldHalcyon022Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (EmeraldHalcyon023Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        (Glazed90Rom _) => FRLG_SPECIES_NAME_ENTRY_LENGTH,
        _ => FRLG_SPECIES_NAME_ENTRY_LENGTH  // default to FRLG
    );
}

/** 
 * size of smove name string in bytes
 */
uint move_names_entry_length(PkmnRomType rom_type) {
    enum int GEN3_MOVE_NAME_ENTRY_LENGTH = 12 + 1;

    return rom_type.match!(
        _ => GEN3_MOVE_NAME_ENTRY_LENGTH  // default to FRLG
    );
}

/** 
 * address of "gBaseStats" symbol
 * how to find:
 * search in binary for something resembling
 * 2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01 07 41 00 00 03 00 00  // BULBASAUR
 * then, subtract the species_basestats_entry_length to get the offset
 * by the way, this means
    .baseHP        = 45,
    .baseAttack    = 49,
    .baseDefense   = 49,
    .baseSpeed     = 45,
    .baseSpAttack  = 65,
    .baseSpDefense = 65,
 */
uint species_basestats_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x2547A0 - rom_type.species_basestats_entry_length,
        (LeafGreenURom _) => 0x25477C - rom_type.species_basestats_entry_length,
        (ShinyGoldSigma139Rom _) => 0xA6BCEC - rom_type.species_basestats_entry_length,
        (EmeraldURom _) => 0x3203E8 - rom_type.species_basestats_entry_length,
        (EmeraldHalcyon021Rom _) => 0x38089C,
        (EmeraldHalcyon022Rom _) => 0x380858,
        (EmeraldHalcyon023Rom _) => 0x380898,
        (Glazed90Rom _) => 0x3203E8 - rom_type.species_basestats_entry_length,
        _ => 0,
    );
}
enum OffsetFinder[] SPECIES_TABLE_FINDERS = [
    // default: Bulbasaur (+8 lead padding)
    // OffsetFinder("Bulbasaur Gen3 Base", 8 - 0x1C, mixin(hex_array!("00 00 00 00 00 00 00 00 2D 31 31 2D 41 41"))),
    // OffsetFinder("Bulbasaur Gen3 Base FRLG", 8 - 0x1C,
    //     mixin(hex_array!("00 00 00 00 00 00 00 00 2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01"))),
    OffsetFinder("Bulbasaur Gen3 Base", 8 - 0x1C,
        mixin(hex_array!("00 00 00 00 00 00 00 00 2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01"))),
    OffsetFinder("Bulbasaur Gen3 SGS", 8 - 0x1C,
        mixin(hex_array!("02 02 00 00 00 00 00 00 2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01"))),
    OffsetFinder("Bulbasaur Pokemon Expansion", 8 - 0x24,
        mixin(hex_array!("00 00 00 00 00 00 00 00 2D 31 31 2D 41 41 0C 03 2D 00 40 00 00 01 00 00 00 00"))),
];

/** 
 * address of "gSpeciesNames" symbol
 */
uint species_names_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x245EE0,
        (ShinyGoldSigma139Rom _) => 0xA68340,
        (EmeraldHalcyon021Rom _) => 0x36BD90,
        (EmeraldHalcyon022Rom _) => 0x36BD28,
        (EmeraldHalcyon023Rom _) => 0x36BD68,
        (Glazed90Rom _) => 0x3185C8,
        _ => 0,
    );
}
enum OffsetFinder[] SPECIES_NAME_FINDERS = [
    // capitalized: BULBASAUR
    OffsetFinder("BULBASAUR", 9 - 11, mixin(hex_array!("AC AC AC AC AC AC AC AC FF BC CF C6 BC BB CD BB CF CC"))),
    // decapitalized: Bulbasaur
    OffsetFinder("Bulbasaur", 9 - 11, mixin(hex_array!("AC AC AC AC AC AC AC AC FF BC E9 E0 D6 D5 E7 D5 E9 E6"))),
];

/** 
 * address of "gItems" symbol
 * in RS looks like:
 *      AC AC AC AC AC AC AC AC FF 00 00 00 00 00 00 00 00 00 00 00 DA 55 3C 08 00 00 01 04 11 A7 0C 08 00 00 00 00 00 00 00 00 00 00 00 00  // ????????
 *      C7 BB CD CE BF CC 00 BC BB C6 C6 FF 00 00 01 00 00 00 00 00 A0 20 3C 08 00 00 02 00 00 00 00 00 02 00 00 00 65 A2 0C 08 00 00 00 00  // MASTER BALL
 * in ? looks like:
 * decapitalized? look for
 *      C7 D5 E7 E8 D9 ...
 */
uint item_table_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x3DB054 - rom_type.item_table_entry_length,
        (LeafGreenURom _) => 0x3DAE64 - rom_type.item_table_entry_length,
        (ShinyGoldSigma139Rom _) => 0x3DB054 - rom_type.item_table_entry_length,
        (EmeraldURom _) => 0x5839CC - rom_type.item_table_entry_length,
        (EmeraldHalcyon021Rom _) => 0x63C924,
        (EmeraldHalcyon022Rom _) => 0x63C8E0,
        (EmeraldHalcyon023Rom _) => 0x63C920,
        (Glazed90Rom _) => 0x5839CC - rom_type.item_table_entry_length,
        _ => 0,
    );
}
enum OffsetFinder[] ITEM_TABLE_FINDERS = [
    // capitalized: MASTER BALL
    OffsetFinder("MASTER BALL", 13 - 0x2C, mixin(hex_array!("08 00 00 00 00 00 00 00 00 00 00 00 00 C7 BB CD CE BF CC"))),
    // decapitalized: Master Ball
    OffsetFinder("Master Ball", 13 - 0x2C, mixin(hex_array!("08 00 00 00 00 00 00 00 00 00 00 00 00 C7 D5 E7 E8 D9"))),
    // item expansion: Pok?? Ball
    OffsetFinder("Pok?? Ball", 13 - 0x2C, mixin(hex_array!("08 00 00 00 00 00 00 00 00 00 00 00 00 CA E3 DF 1B 00 BC D5 E0 E0"))),
];

/** symbol: gBattleMoves */
uint move_table_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x250C04,
        (EmeraldHalcyon021Rom _) => 0x3779EC,
        (EmeraldHalcyon022Rom _) => 0x3779A8,
        (EmeraldHalcyon023Rom _) => 0x3779E8,
        _ => 0,
    );
}
enum OffsetFinder[] MOVE_TABLE_FINDERS = [
    // capitalized: FOCUS ENERGY
    OffsetFinder("MOVE_POUND Base Gen 3", 10 - 12,
        mixin(hex_array!("00 00 00 00 00 00 00 00 00 00 00 28 00 64 23 00 00 00 33 00 00 00"))),
    OffsetFinder("MOVE_POUND Pokemon Expansion", 22 - 22,
        mixin(hex_array!("00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 28 00 64 23 00 00 00 00 00 00 33"))),
];

/** 
 * address of "gMoveNames" symbol
 */
uint move_names_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x247094,
        (LeafGreenURom _) => 0x247070,
        (ShinyGoldSigma139Rom _) => 0xC61360,
        (EmeraldURom _) => 0x31977C,
        (EmeraldHalcyon021Rom _) => 0x36F1BA,
        (EmeraldHalcyon022Rom _) => 0x36F152,
        (EmeraldHalcyon023Rom _) => 0x36F192,
        (Glazed90Rom _) => 0x31977C,
        _ => 0,
    );
}
enum OffsetFinder[] MOVE_NAME_FINDERS = [
    OffsetFinder("POUND, KARATE CHOP", 0 - 13,
        mixin(hex_array!("CA C9 CF C8 BE FF 00 00 00 00 00 00 00 C5 BB CC BB CE BF 00 BD C2"))),
    OffsetFinder("Pound, Karate Chop", 0 - 13,
        mixin(hex_array!("CA E3 E9 E2 D8 FF 00 00 00 00 00 00 00 C5 D5 E6 D5 E8 D9 00 BD DC"))),
    OffsetFinder("POUND, EARTH POWER", 0 - 13,
        mixin(hex_array!("CA C9 CF C8 BE FF 00 00 00 00 00 00 00 BF BB CC CE C2 00 CA C9 D1 BF CC FF 00"))),
];

uint species_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (FireRedURom _) => 412,
        (LeafGreenURom _) => 412,
        (ShinyGoldSigma139Rom _) => 923,
        (EmeraldURom _) => 412,
        (EmeraldHalcyon021Rom _) => 1024,
        (EmeraldHalcyon022Rom _) => 1024,
        (EmeraldHalcyon023Rom _) => 1024,
        (Glazed90Rom _) => 1024,
        _ => 412,
    );
}

uint item_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (FireRedURom _) => 375,
        (LeafGreenURom _) => 375,
        (ShinyGoldSigma139Rom _) => 375,
        (EmeraldURom _) => 375,
        (EmeraldHalcyon021Rom _) => 960,
        (EmeraldHalcyon022Rom _) => 960,
        (EmeraldHalcyon023Rom _) => 960,
        (Glazed90Rom _) => 960,
        _ => 375,
    );
}

uint move_table_size(PkmnRomType rom_type) {
    // fix syntax like one above

    return rom_type.match!(
        (FireRedURom _) => 355,
        (LeafGreenURom _) => 355,
        (ShinyGoldSigma139Rom _) => 755,
        (EmeraldURom _) => 355,
        (EmeraldHalcyon021Rom _) => 755,
        (EmeraldHalcyon022Rom _) => 755,
        (EmeraldHalcyon023Rom _) => 755,
        (Glazed90Rom _) => 355,
        _ => 355,
    );
}

// misc offset finders

/** symbol: gTypeNames */
enum OffsetFinder[] TYPE_NAME_FINDERS = [
    OffsetFinder("Gen 3 Base", 0, 
        mixin(hex_array!("C8 C9 CC C7 BB C6 FF C0 C3 C1 C2 CE FF 00 C0 C6 D3 C3 C8 C1 FF"))),
    OffsetFinder("Pokemon Expansion", 0,
        mixin(hex_array!("C8 E3 E6 E1 D5 E0 FF C0 DD DB DC E8 FF 00 C0 E0 ED DD E2 DB FF"))),
];

// /** symbol: sTypeEffectivenessTable */
// enum OffsetFinder[] TYPE_EFFECTIVENESS_TABLE_FINDERS = [

// ];

// /** symbol: gLevelUpLearnsets */
// enum OffsetFinder[] LEVEL_UP_LEARNSET_FINDERS = [
//     OffsetFinder("Gen 3 Base", 0, mixin(hex_array!(""))),
// ];

/** symbol: sBulbasaurLevelUpLearnset */
uint bulbasaur_learnset_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x257494,
        (LeafGreenURom _) => 0x257470,
        (ShinyGoldSigma139Rom _) => 0x257494,
        (EmeraldURom _) => 0x3230DC,
        (EmeraldHalcyon021Rom _) => 0x38B354,
        (EmeraldHalcyon022Rom _) => 0x38B310,
        (EmeraldHalcyon023Rom _) => 0x38B350,
        (Glazed90Rom _) => 0x36A1F4,
        _ => 0,
    );
}

enum BULBASAUR_LEARNSET_VARIANT_16 = 0x01;
enum BULBASAUR_LEARNSET_VARIANT_32 = 0x02;
uint bulbasaur_learnset_variant(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => BULBASAUR_LEARNSET_VARIANT_16,
        (LeafGreenURom _) => BULBASAUR_LEARNSET_VARIANT_16,
        (ShinyGoldSigma139Rom _) => BULBASAUR_LEARNSET_VARIANT_16,
        (EmeraldURom _) => BULBASAUR_LEARNSET_VARIANT_16,
        (EmeraldHalcyon021Rom _) => BULBASAUR_LEARNSET_VARIANT_32,
        (EmeraldHalcyon022Rom _) => BULBASAUR_LEARNSET_VARIANT_32,
        (EmeraldHalcyon023Rom _) => BULBASAUR_LEARNSET_VARIANT_32,
        (Glazed90Rom _) => BULBASAUR_LEARNSET_VARIANT_16,
        _ => 16,
    );
}

enum OffsetFinder[] BULBASAUR_LEARNSET_FINDERS = [
    OffsetFinder("Bulbasaur Gen 3 Base FR", 0, mixin(hex_array!("21 02 2D 08 49 0E")), BULBASAUR_LEARNSET_VARIANT_16),
    OffsetFinder("Bulbasaur Glazed", 0, mixin(hex_array!("21 02 2D 02 16 06 4A 0C")), BULBASAUR_LEARNSET_VARIANT_16),
    OffsetFinder("Bulbasaur Pokemon Expansion", 0,
        mixin(hex_array!("21 00 01 00 2D 00 03 00 49 00 07 00")), BULBASAUR_LEARNSET_VARIANT_32),
];

/** symbol: gLevelUpLearnsets */
uint level_up_learnsets_offset(PkmnRomType rom_type) {
    return rom_type.match!(
        (FireRedURom _) => 0x25D7B4,
        (LeafGreenURom _) => 0x25D794,
        (ShinyGoldSigma139Rom _) => 0xA74F64, // unsure about this one
        (EmeraldURom _) => 0x32937C,
        (EmeraldHalcyon021Rom _) => 0x3B29D8,
        (EmeraldHalcyon022Rom _) => 0x3B2994,
        (EmeraldHalcyon023Rom _) => 0x3B29D4,
        (Glazed90Rom _) => 0x32937C,
        _ => 0,
    );
}
