module pokegame;

import std.file;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm.comparison;
import std.bitmanip;
import std.range;

import util;

alias read_bin = std.bitmanip.read;

enum Gender {
    Male,
    Female
}

enum PkmnNature {
    Hardy = 0,
    Lonely = 1,
    Brave = 2,
    Adamant = 3,
    Naughty = 4,
    Bold = 5,
    Docile = 6,
    Relaxed = 7,
    Impish = 8,
    Lax = 9,
    Timid = 10,
    Hasty = 11,
    Serious = 12,
    Jolly = 13,
    Naive = 14,
    Modest = 15,
    Mild = 16,
    Quiet = 17,
    Bashful = 18,
    Rash = 19,
    Calm = 20,
    Gentle = 21,
    Sassy = 22,
    Careful = 23,
    Quirky = 24,
}

enum PkmnTypeGen3 {
    Normal = 0,
    Fighting = 1,
    Flying = 2,
    Poison = 3,
    Ground = 4,
    Rock = 5,
    Bug = 6,
    Ghost = 7,
    Steel = 8,
    Fairy = 9, // SGS only
    Fire = 10,
    Water = 11,
    Grass = 12,
    Electric = 13,
    Psychic = 14,
    Ice = 15,
    Dragon = 16,
    Dark = 17,
}

enum PkmnTypeGeneral {
    Normal = 0,
    Fighting = 1,
    Flying = 2,
    Poison = 3,
    Ground = 4,
    Rock = 5,
    Bug = 6,
    Ghost = 7,
    Steel = 8,
    Fire = 9,
    Water = 10,
    Grass = 11,
    Electric = 12,
    Psychic = 13,
    Ice = 14,
    Dragon = 15,
    Dark = 16,
    Fairy = 17,
    Question = 18,
}

enum ubyte[] BULBASAUR_SPECIES_DATA = [
        0x2D, 0x31, 0x31, 0x2D, 0x41, 0x41, 0x0C, 0x03, 0x2D, 0x40, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x1F, 0x14, 0x46, 0x03, 0x01, 0x07, 0x41,
        0x00, 0x00, 0x03, 0x00, 0x00
    ];

enum int SPECDATA_ENTRY_LENGTH = 28;

enum PkmnROMSpeciesDataOffsets : uint {
    /*
        bulbasaur (ID: 0x01) offset
        data looks like:
        2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01 07 41 00 00 03 00 00  // BULBASAUR
    */
    OFFSET_BULBASAUR_FR_U = 0x2547A0, // fire red en-us
    OFFSET_BULBASAUR_LG_U = 0x25477C, // leaf green en-us
    OFFSET_BULBASAUR_SGS_138 = 0xA6BCEC,
}

enum ubyte[] MASTERBALL_ITEM_DATA_FR = [
        0xC7, 0xBB, 0xCD, 0xCE, 0xBF, 0xCC, 0x00, 0xBC, 0xBB, 0xC6, 0xC6, 0xFF,
        0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0xCC, 0x4E, 0x3D,
        0x08, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00,
        0x00, 0x1D, 0x1E, 0x0A, 0x08, 0x00, 0x00, 0x00, 0x00
    ];

enum ubyte[] MASTERBALL_ITEM_DATA_MATCH = [
        0xFF, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0xCC, 0x4E, 0x3D,
        0x08, 0x00, 0x00, 0x03, 0x00
    ];

enum int ITEMTBL_ENTRY_LENGTH = 44;

enum PkmnROMItemTblOffsets : uint {
    /*
        masterball (ID: 0x01) offset
        in FRLG, data looks like:
        C7 BB CD CE BF CC 00 BC BB C6 C6 FF 00 00 01 00 00 00 00 00 CC 4E 3D 08 00 00 03 00 00 00 00 00 02 00 00 00 1D 1E 0A 08 00 00 00 00
        in SGS, data looks like:
        C7 D5 E7 E8 D9 E6 00 BC D5 E0 E0 FF 00 00 01 00 00 00 00 00 CC 4E 3D 08 00 00 03 00 68 05 46 08 02 00 00 00 1D 1E 0A 08 00 00 00 00

        a good place to match: (+11)
        FF 00 00 01 00 00 00 00 00 CC 4E 3D 08 00 00 03 00
    */
    OFFSET_MASTERBALL_FR_U = 0x3DB054, // fire red en-us
    // OFFSET_MASTERBALL_LG_U = 0x3DAE64, // leaf green en-us THIS IS WRONG
    OFFSET_MASTERBALL_SGS_138 = 0x3DB054,
}

enum PkmnROMDetect {
    UNKNOWN,
    FIRE_RED_U,
    LEAF_GREEN_U,
    SGS_138,
}

struct Personality {
    ubyte raw_gender;
    Gender gender;

    ubyte raw_extra_ability;

    ubyte raw_nature;
    PkmnNature nature;

    ushort raw_shiny;
    bool shiny;

    string toString() const {
        import std.string : format;

        return format("gender: %s, nature: %s, shiny: %s", gender, nature, shiny);
    }
}

align(1) {
    struct PkmnROMSpecies {
    align(1):
        struct {
            ubyte hp;
            ubyte atk;
            ubyte def;
            ubyte spd;
            ubyte satk;
            ubyte sdef;
        }

        struct {
            ubyte type1;
            ubyte type2;
        }

        struct {
            ubyte catch_rate;
            ubyte exp_yield;
            ushort effort_yield;
        }

        struct {
            ushort item1;
            ushort item2;
            ubyte gender;
        }

        ubyte egg_cycles;
        ubyte friendship;
        ubyte lvl_up_type;
        struct {
            ubyte egg_group_1;
            ubyte egg_group_2;
        }

        struct {
            ubyte ability1;
            ubyte ability2;
        }

        ubyte safari_zone_rate;
        ubyte color_flip;
        ushort unknown0;

        string toString() const {
            import std.string : format;

            return format("hp: %s, atk: %s, def: %s, spd: %s, satk: %s, sdef: %s, type1: %s, type2: %s", hp, atk,
                    def, spd, satk, sdef, type1.to!PkmnTypeGen3, type2.to!PkmnTypeGen3) ~ format(", gender: %s",
                    gender);
        }
    }

    struct PkmnROMItem {
    align(1):
        ubyte[14] name;
        ushort index;
        ushort price;
        ubyte hold_effect;
        ubyte parameter0;
        uint description_ptr;
        ushort mystery0;
        ubyte pocket;
        ubyte type;
        uint field_usage_ptr;
        uint battle_usage;
        uint battle_usage_ptr;
        uint parameter1;

        string toString() const {
            import std.string : format;

            return format("id: %s, name: %s, price: %s", index, decode_gba_text(name.dup).strip(), price);
        }
    }
}

class PkmnROM {
    public ubyte[] rom_buf;
    public PkmnROMDetect rom_type;

    void read_from(string path) {
        rom_buf = cast(ubyte[]) std.file.read(path);
    }

    uint get_specdata_offset_for_rom(PkmnROMDetect rom_type) {
        switch (rom_type) {
        case PkmnROMDetect.FIRE_RED_U:
            return PkmnROMSpeciesDataOffsets.OFFSET_BULBASAUR_FR_U;
        case PkmnROMDetect.LEAF_GREEN_U:
            return PkmnROMSpeciesDataOffsets.OFFSET_BULBASAUR_LG_U;
        case PkmnROMDetect.SGS_138:
            return PkmnROMSpeciesDataOffsets.OFFSET_BULBASAUR_SGS_138;
        default:
            return 0;
        }
    }

    uint get_itemtbl_offset_for_rom(PkmnROMDetect rom_type) {
        switch (rom_type) {
        case PkmnROMDetect.FIRE_RED_U:
            return PkmnROMItemTblOffsets.OFFSET_MASTERBALL_FR_U;
        case PkmnROMDetect.SGS_138:
            return PkmnROMItemTblOffsets.OFFSET_MASTERBALL_SGS_138;
        default:
            assert(0, "Unknown");
        }
    }

    bool detect_rom_type() {
        // check third byte of species data
        if (rom_buf[PkmnROMSpeciesDataOffsets.OFFSET_BULBASAUR_FR_U + 2] == 0x31) {
            rom_type = PkmnROMDetect.FIRE_RED_U;
            return true;
        }
        if (rom_buf[PkmnROMSpeciesDataOffsets.OFFSET_BULBASAUR_LG_U + 2] == 0x31) {
            rom_type = PkmnROMDetect.LEAF_GREEN_U;
            return true;
        }
        if (rom_buf[PkmnROMSpeciesDataOffsets.OFFSET_BULBASAUR_SGS_138 + 2] == 0x31) {
            rom_type = PkmnROMDetect.SGS_138;
            return true;
        }

        rom_type = PkmnROMDetect.UNKNOWN;
        return false;
    }

    bool verify() {
        // detect
        detect_rom_type();

        // ensure that bulbasaur data is found at offset
        // read 28 bytes from ROM at address
        auto specdata_offset = get_specdata_offset_for_rom(rom_type);
        // auto offset = get_specdata_offset_for_rom(PkmnROMDetect.SGS_138);

        auto specdata_offset_end = specdata_offset + SPECDATA_ENTRY_LENGTH;
        auto specdata_rom_slice = rom_buf[specdata_offset .. specdata_offset_end];
        // writefln("rom slice (0x%06x-0x%06x): %s", offset, offset_end, rom_slice);

        // compare with bulbasaur seq
        auto is_specdata_equal = equal(specdata_rom_slice, BULBASAUR_SPECIES_DATA);

        if (!is_specdata_equal) {
            assert(0, format("rom (detected %s) specdata slice (0x%06x-0x%06x) did not match BULBASAUR seq: %s",
                    rom_type, specdata_offset, specdata_offset_end, specdata_rom_slice));
        }

        // ensure that masterball data is found at offset
        auto itemtbl_offset = get_itemtbl_offset_for_rom(rom_type) + 11;
        // auto offset = get_itemtbl_offset_for_rom(PkmnROMDetect.SGS_138);

        auto itemtbl_offset_end = itemtbl_offset + MASTERBALL_ITEM_DATA_MATCH.length;
        auto itemtbl_rom_slice = rom_buf[itemtbl_offset .. itemtbl_offset_end];
        // writefln("rom slice (0x%06x-0x%06x): %s", offset, offset_end, rom_slice);

        // compare with masterball seq
        auto is_itemtbl_equal = equal(itemtbl_rom_slice, MASTERBALL_ITEM_DATA_MATCH);

        if (!is_itemtbl_equal) {
            assert(0, format(
                    "rom (detected %s) itemtbl slice (0x%06x-0x%06x) did not match MASTERBALL match seq: %s (target: %s)",
                    rom_type, itemtbl_offset, itemtbl_offset_end,
                    itemtbl_rom_slice, MASTERBALL_ITEM_DATA_MATCH));
        }

        return is_specdata_equal && is_itemtbl_equal;
    }

    PkmnROMSpecies* get_species_info(uint species) {
        auto offset = get_specdata_offset_for_rom(rom_type) + (
                SPECDATA_ENTRY_LENGTH * (species - 0x01));

        return cast(PkmnROMSpecies*)&rom_buf[offset];
    }

    PkmnROMItem* get_item_info(uint item) {
        auto offset = get_itemtbl_offset_for_rom(rom_type) + (ITEMTBL_ENTRY_LENGTH * (item - 0x01));

        // writefln("data (0x%06x): %s", offset, rom_buf[offset .. (offset + 44)]);

        return cast(PkmnROMItem*)&rom_buf[offset];
    }
}