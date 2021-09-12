module pokegame;

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

enum PkmnROMSpeciesData {
    /*
        bulbasaur (ID: 0x01) offset
        data looks like:
        2D 31 31 2D 41 41 0C 03 2D 40 00 01 00 00 00 00 1F 14 46 03 01 07 41 00 00 03 00 00  // BULBASAUR
    */
    OFFSET_BULBASAUR_FR = 0x2547A0,
    OFFSET_BULBASAUR_SGS_138 = 0xA6BCEC,
}

class PkmnROM {
    public ubyte[] rom_buf;

    void read_from(string path) {
        rom_buf = cast(ubyte[]) std.file.read(path);
    }

    bool verify() {
        // ensure that bulbasaur data is found at offset

        return false;
    }
}
