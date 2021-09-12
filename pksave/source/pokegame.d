module pokegame;

import std.file;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm.comparison;

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

enum ubyte[] BULBASAUR_SPECIES_DATA = [
        0x2D, 0x31, 0x31, 0x2D, 0x41, 0x41, 0x0C, 0x03, 0x2D, 0x40, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x1F, 0x14, 0x46, 0x03, 0x01, 0x07, 0x41,
        0x00, 0x00, 0x03, 0x00, 0x00
    ];

enum PkmnROMSpeciesData : uint {
    /*
        bulbasaur (ID: 0x01) offset
        data looks like:
        2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01 07 41 00 00 03 00 00  // BULBASAUR
    */
    OFFSET_BULBASAUR_FR = 0x2547A0,
    OFFSET_BULBASAUR_SGS_138 = 0xA6BCEC,
}

enum PkmnROMDetect {
    UNKNOWN,
    FR,
    LG,
    SGS_138,
}

class PkmnROM {
    public ubyte[] rom_buf;
    public PkmnROMDetect rom_type;

    void read_from(string path) {
        rom_buf = cast(ubyte[]) std.file.read(path);
    }

    uint get_specdata_offset_for_rom(PkmnROMDetect rom_type) {
        switch (rom_type) {
            case PkmnROMDetect.FR:
                return PkmnROMSpeciesData.OFFSET_BULBASAUR_FR;
            case PkmnROMDetect.SGS_138:
                return PkmnROMSpeciesData.OFFSET_BULBASAUR_SGS_138;
            default:
                return 0;
        }
    }

    void detect_rom_type() {
        rom_type = PkmnROMDetect.FR;
    }

    bool verify() {
        // detect
        detect_rom_type();

        // ensure that bulbasaur data is found at offset
        // writefln("verifying rom");

        // read 28 bytes from ROM at address
        auto offset = get_specdata_offset_for_rom(rom_type);
        // auto offset = get_specdata_offset_for_rom(PkmnROMDetect.SGS_138);

        auto offset_end = offset + 28;
        auto rom_slice = rom_buf[offset..offset_end];
        // writefln("rom slice (0x%06x-0x%06x): %s", offset, offset_end, rom_slice);

        // compare with bulbasaur seq
        auto is_equal = equal(rom_slice, BULBASAUR_SPECIES_DATA);

        // writefln("rom slice specdata match: %s", is_equal);

        if (!is_equal) {
            assert(0, format("rom (detected %s) slice (0x%06x-0x%06x) did not match BULBASAUR seq: %s", rom_type, offset, offset_end, rom_slice));
        }

        return is_equal;
    }
}
