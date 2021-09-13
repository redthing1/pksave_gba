module pokegame;

import std.file;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm.comparison;
import std.bitmanip;
import std.range;

import util;

public import data;

alias read_bin = std.bitmanip.read;


enum ubyte[] BULBASAUR_SPECIES_DATA = [
        0x2D, 0x31, 0x31, 0x2D, 0x41, 0x41, 0x0C, 0x03, 0x2D, 0x40, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x1F, 0x14, 0x46, 0x03, 0x01, 0x07, 0x41,
        0x00, 0x00, 0x03, 0x00, 0x00
    ];

enum int SPECDATA_ENTRY_LENGTH = 28;

enum PkmnROMSpeciesDataInfo : uint {
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

enum PkmnROMItemTblInfo : uint {
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

enum PkmnROMDetect : uint {
    UNKNOWN,
    FIRE_RED_U,
    LEAF_GREEN_U,
    SGS_138,
}

class PkmnROMTables {
    public static uint[uint] ITEMTBL_SIZE;
    public static uint[uint] OFFSET_BULBASAUR;
    public static uint[uint] OFFSET_MASTERBALL;
}

class PkmnROM {
    public ubyte[] rom_buf;
    public PkmnROMDetect rom_type;

    this() {
        // populate table
        PkmnROMTables.ITEMTBL_SIZE = [
            PkmnROMDetect.UNKNOWN: 0,
            PkmnROMDetect.FIRE_RED_U: 375,
            PkmnROMDetect.SGS_138: 375,
        ];
    }

    void read_from(string path) {
        rom_buf = cast(ubyte[]) std.file.read(path);
    }

    uint get_specdata_offset_for_rom(PkmnROMDetect rom_type) {
        switch (rom_type) {
        case PkmnROMDetect.FIRE_RED_U:
            return PkmnROMSpeciesDataInfo.OFFSET_BULBASAUR_FR_U;
        case PkmnROMDetect.LEAF_GREEN_U:
            return PkmnROMSpeciesDataInfo.OFFSET_BULBASAUR_LG_U;
        case PkmnROMDetect.SGS_138:
            return PkmnROMSpeciesDataInfo.OFFSET_BULBASAUR_SGS_138;
        default:
            return 0;
        }
    }

    uint get_itemtbl_offset_for_rom(PkmnROMDetect rom_type) {
        switch (rom_type) {
        case PkmnROMDetect.FIRE_RED_U:
            return PkmnROMItemTblInfo.OFFSET_MASTERBALL_FR_U;
        case PkmnROMDetect.SGS_138:
            return PkmnROMItemTblInfo.OFFSET_MASTERBALL_SGS_138;
        default:
            assert(0, "Unknown");
        }
    }

    bool detect_rom_type() {
        // check third byte of species data
        if (rom_buf[PkmnROMSpeciesDataInfo.OFFSET_BULBASAUR_FR_U + 2] == 0x31) {
            rom_type = PkmnROMDetect.FIRE_RED_U;
            return true;
        }
        if (rom_buf[PkmnROMSpeciesDataInfo.OFFSET_BULBASAUR_LG_U + 2] == 0x31) {
            rom_type = PkmnROMDetect.LEAF_GREEN_U;
            return true;
        }
        if (rom_buf[PkmnROMSpeciesDataInfo.OFFSET_BULBASAUR_SGS_138 + 2] == 0x31) {
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

    PkmnROMItem[] get_item_info_table() {
        PkmnROMItem[] list;

        for (int i = 0; i < PkmnROMTables.ITEMTBL_SIZE[rom_type]; i++) {
            // dereference and copy
            PkmnROMItem item = *get_item_info(i);
            list ~= item;
        }

        return list;
    }
}
