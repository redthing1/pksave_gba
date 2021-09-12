module pokesave;

import libspec;
import std.file;
import std.stdio;

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

    void verify() {
        // verify validity
        // check savtype and keys
    }
}
