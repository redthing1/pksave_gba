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
            auto rom_type = cast(PkmnRomType) T();
            auto spec_0_off = rom_type.species_basestats_offset;
            if (rom_buf[spec_0_off + (rom_type.species_basestats_entry_length * 1) + 2] == species)
                return true;

            return false;
        }

        bool check_bulbasaur(T)() {
            enum int SPECIES_BULBASAUR = 0x31;
            return check_first_species!T(SPECIES_BULBASAUR);
        }

        bool check_sig_byte(uint offset, ubyte expect) {
            return rom_buf[offset] == expect;
        }

        // hack roms
        if (check_bulbasaur!ShinyGoldSigma139Rom())
            return cast(PkmnRomType) ShinyGoldSigma139Rom();
        if (check_bulbasaur!EmeraldHalcyon021Rom())
            return cast(PkmnRomType) EmeraldHalcyon021Rom();
        if (check_bulbasaur!Glazed90Rom() && check_sig_byte(0x430, 0x18))
            return cast(PkmnRomType) Glazed90Rom();
        
        // base gen 3 game roms
        if (check_bulbasaur!EmeraldURom())
            return cast(PkmnRomType) EmeraldURom();
        if (check_bulbasaur!FireRedURom())
            return cast(PkmnRomType) FireRedURom();
        if (check_bulbasaur!LeafGreenURom())
            return cast(PkmnRomType) LeafGreenURom();

        return cast(PkmnRomType) UnknownGen3Rom();
    }

    bool verify() {
        // detect
        rom_type = detect_rom_type();

        return verify_species_table()
            && verify_item_table();
    }

    bool verify_species_table() {
        uint tbl_offset = rom_type.species_basestats_offset;
        uint tbl_size = rom_type.species_table_size;

        return true;
    }

    bool verify_item_table() {
        uint tbl_offset = rom_type.item_table_offset;
        uint tbl_size = rom_type.item_table_size;

        return true;
    }

    @property num_species() {
        return rom_type.species_table_size;
    }

    @property num_items() {
        return rom_type.item_table_size;
    }

    PkmnROMSpecies* get_species_basestats(uint species) {
        auto offset = rom_type.species_basestats_offset
            + (rom_type.species_basestats_entry_length * species);

        return cast(PkmnROMSpecies*)&rom_buf[offset];
    }

    ubyte[] get_species_name(uint species) {
        auto offset = rom_type.species_names_offset
            + (rom_type.species_names_entry_length * species);

        ubyte* data_ptr = &rom_buf[offset];
        return data_ptr[0..rom_type.species_names_entry_length];
    }

    PkmnROMItem* get_item_info(uint item) {
        auto offset = rom_type.item_table_offset
            + (rom_type.item_table_entry_length * item);

        // writefln("data (0x%06x): %s", offset, rom_buf[offset .. (offset + 44)]);

        return cast(PkmnROMItem*)&rom_buf[offset];
    }

    PkmnROMSpecies[] get_species_basestats_table() {
        PkmnROMSpecies[] list;

        for (int i = 0; i < rom_type.species_table_size; i++) {
            // dereference and copy
            PkmnROMSpecies item = *get_species_basestats(i);
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
