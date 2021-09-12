module pokesave;

import libspec;
import std.file;
import std.stdio;
import std.string;

class PokeSave {
    public ubyte[] savfile_buf;
    public gba_save_t* loaded_save;

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

    bool verify() {
        // verify main save validity
        // check savtype
        if (loaded_save.type != gba_savetype_t.GBA_TYPE_FRLG) {
            assert(0, "save was not FRLG!");
            // return false;
        }
        // check keys
        auto key1 = gba_get_security_key(
                loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY_OFFSET).key;
        auto key2 = gba_get_security_key(
                loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY2_OFFSET).key;
        if (key1 != key2) {
            assert(0, "FRLG keys did not match!");
            // return false;
        }

        // done
        return true;
    }

    bool verify_party() {
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
            assert(is_valid, format("party pkmn %s is corrupted", i));
        }
        return all_valid;
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
}
