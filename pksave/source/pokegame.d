module pokegame;

import std.file;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm.comparison;
import std.bitmanip;
import std.range;
import std.sumtype;

import util;

public import data;
public import pokerom;

alias read_bin = std.bitmanip.read;

class PkmnROM {
    public ubyte[] rom_buf;
    public PkmnRomType rom_type = UnknownGen3Rom();

    this() {
    }

    void read_from(string path) {
        rom_buf = cast(ubyte[]) std.file.read(path);
    }

    PkmnRomType detect_rom_type() {
        // utility function to check if the first entry is bulbasaur, as expected
        bool check_first_species(T)(int species) {
            if (rom_buf[((cast(PkmnRomType) T()).species_data_offset) + 2] == species)
                return true;

            return false;
        }

        bool check_bulbasaur(T)() {
            enum int SPECIES_BULBASAUR = 0x31;
            return check_first_species!T(SPECIES_BULBASAUR);
        }

        if (check_bulbasaur!FireRedURom())
            return cast(PkmnRomType) FireRedURom();
        if (check_bulbasaur!LeafGreanURom())
            return cast(PkmnRomType) LeafGreanURom();
        if (check_bulbasaur!ShinyGoldSigma138Rom())
            return cast(PkmnRomType) ShinyGoldSigma138Rom();
        if (check_bulbasaur!EmeraldURom())
            return cast(PkmnRomType) EmeraldURom();
        if (check_bulbasaur!EmeraldHalcyonRom())
            return cast(PkmnRomType) EmeraldHalcyonRom();

        return cast(PkmnRomType) UnknownGen3Rom();
    }

    bool verify() {
        // detect
        rom_type = detect_rom_type();

        return verify_species_table()
            && verify_item_table();
    }

    bool verify_species_table() {
        uint tbl_offset = rom_type.species_data_offset;
        uint tbl_size = rom_type.species_table_size;

        return true;
    }

    bool verify_item_table() {
        uint tbl_offset = rom_type.item_table_offset;
        uint tbl_size = rom_type.item_table_size;

        return true;
    }

    PkmnROMSpecies* get_species_info(uint species) {
        auto offset = rom_type.species_data_offset
            + (rom_type.species_data_entry_length * species);

        return cast(PkmnROMSpecies*)&rom_buf[offset];
    }

    PkmnROMItem* get_item_info(uint item) {
        auto offset = rom_type.item_table_offset
            + (rom_type.item_table_entry_length * item);

        // writefln("data (0x%06x): %s", offset, rom_buf[offset .. (offset + 44)]);

        return cast(PkmnROMItem*)&rom_buf[offset];
    }

    PkmnROMSpecies[] get_species_info_table() {
        PkmnROMSpecies[] list;

        for (int i = 0; i < rom_type.species_table_size; i++) {
            // dereference and copy
            PkmnROMSpecies item = *get_species_info(i);
            list ~= item;
        }

        return list;
    }

    PkmnROMItem[] get_item_info_table() {
        PkmnROMItem[] list;

        for (int i = 0; i < rom_type.item_table_size; i++) {
            // dereference and copy
            PkmnROMItem item = *get_item_info(i);
            list ~= item;
        }

        return list;
    }
}
