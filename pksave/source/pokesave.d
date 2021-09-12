module pokesave;

import libspec;
import std.file;
import std.stdio;
import std.string;
import std.conv;
import pokegame;

class PokeSave {
    public ubyte[] savfile_buf;
    public gba_save_t* loaded_save;
    public PkmnROM rom;

    void read_from(string path) {
        savfile_buf = cast(ubyte[]) std.file.read(path);
        loaded_save = gba_read_main_save(cast(const(ubyte)*) savfile_buf);
    }

    void write_to(string path) {
        // copy loaded save buffer
        auto output_sav_buf = new ubyte[](savfile_buf.length);
        output_sav_buf[0 .. $] = savfile_buf[0 .. $]; // copy buffer
        // now save
        gba_write_main_save(cast(ubyte*) output_sav_buf, loaded_save);
        std.file.write(path, output_sav_buf);
    }

    void load_companion_rom(string path) {
        rom = new PkmnROM();
        rom.read_from(path);
        rom.verify();
    }

    bool verify(bool forgive = false) {
        // verify main save validity
        // check savtype
        if (loaded_save.type != gba_savetype_t.GBA_TYPE_FRLG) {
            if (!forgive) assert(0, "save was not FRLG!");
            return false;
        }
        // check keys
        auto key1 = gba_get_security_key(
                loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY_OFFSET).key;
        auto key2 = gba_get_security_key(
                loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY2_OFFSET).key;
        if (key1 != key2) {
            if (!forgive) assert(0, "FRLG keys did not match!");
            return false;
        }

        // done
        return true;
    }

    bool verify_party(bool forgive = false) {
        bool all_valid = true;
        for (int i = 0; i < party.size; i++) {
            auto pkmn = party.pokemon[i];
            ushort original_cksum = pkmn.box.checksum;
            // create a local copy and decrypt
            auto box = pkmn.box;
            pk3_decrypt(&box);
            // verify checksum (by recomputing)
            ushort local_checksum = pk3_checksum(cast(const(ubyte*)) box.block,
                    pk3_encryption.PK3_DATA_SIZE);
            auto is_valid = original_cksum == local_checksum;
            if (!is_valid) {
                all_valid = false;
                if (!forgive) assert(0, format("party pkmn %s is corrupted", i));
            }
        }
        return all_valid;
    }

    @property rom_loaded() {
        return rom != null;
    }

    @property trainer() {
        return gba_get_trainer(loaded_save);
    }

    @property party() {
        return gba_get_party(loaded_save);
    }

    @property money() {
        return gba_get_money(loaded_save);
    }

    @property money(uint value) {
        gba_set_money(loaded_save, value);
    }

    struct Personality {
        ubyte raw_gender;
        ubyte raw_extra_ability;
        
        ubyte raw_nature;
        PkmnNature nature;

        ushort raw_shiny;
        bool shiny;

        string toString() const {
            import std.string: format;
            return format("gender: %s, extra_ability: %s, nature: %s, shiny: %s", raw_gender, raw_extra_ability, nature, shiny);
        }
    }

    Personality parse_personality(pk3_box_t box) {
        Personality per;
        
        per.raw_gender = (box.pid & 0xff);
        
        per.raw_extra_ability = (box.pid & 0x01);

        per.raw_nature = (box.pid % 25);
        per.nature = per.raw_nature.to!PkmnNature();

        ushort pid_high = ((box.pid >> 16) & 0xffff);
        ushort pid_low = (box.pid & 0xffff);
        per.raw_shiny = (box.ot_id ^ box.ot_sid ^ pid_high ^ pid_low);
        per.shiny = per.raw_shiny < 8;

        return per;
    }
}
