module pokegame;

import std.file;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm.comparison;
import std.bitmanip;
import std.range;

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
        // writefln("verifying rom");

        // read 28 bytes from ROM at address
        auto offset = get_specdata_offset_for_rom(rom_type);
        // auto offset = get_specdata_offset_for_rom(PkmnROMDetect.SGS_138);

        auto offset_end = offset + SPECDATA_ENTRY_LENGTH;
        auto rom_slice = rom_buf[offset .. offset_end];
        // writefln("rom slice (0x%06x-0x%06x): %s", offset, offset_end, rom_slice);

        // compare with bulbasaur seq
        auto is_equal = equal(rom_slice, BULBASAUR_SPECIES_DATA);

        // writefln("rom slice specdata match: %s", is_equal);

        if (!is_equal) {
            assert(0, format("rom (detected %s) slice (0x%06x-0x%06x) did not match BULBASAUR seq: %s",
                    rom_type, offset, offset_end, rom_slice));
        }

        return is_equal;
    }

    PkmnROMSpecies* get_species_info(uint species) {
        auto offset = get_specdata_offset_for_rom(rom_type) + (
                SPECDATA_ENTRY_LENGTH * (species - 0x01));
        auto offset_end = offset + SPECDATA_ENTRY_LENGTH;

        auto species_info_slice = rom_buf[offset .. offset_end];

        // return read_raw_species!(PkmnROMSpecies)(raw_data);
        // return read_raw_species!(PkmnROMSpecies, Endian.littleEndian
        // alias read_bin = std.bitmanip.read;
        // return std.bitmanip.read!(PkmnROMSpecies, Endian.littleEndian)(raw_data);

        // writefln("species: %s, offset: 0x%06x", species, offset);
        return cast(PkmnROMSpecies*)&rom_buf[offset];
        // return cast(PkmnROMSpecies*) &species_info_slice;
    }

    PkmnROMItem* get_item_info(uint item) {
        return null;
    }
}
