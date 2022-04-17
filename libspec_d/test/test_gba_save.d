module libspec_d.test.test_gba_save;

import std.stdio;
import std.format;
import std.array;
import std.file;
import core.stdc.stdio;
import core.stdc.string;

import libspec;

enum TESTSAV_BASE = "test_saves/";
enum TESTSAV_FIXBOX2 = TESTSAV_BASE ~ "PokeHalcyonEmerald_v0.2.1__fixbox2.sav";

@("pc_pack_unpack")
unittest {
    auto savfile_buf = cast(ubyte[]) std.file.read(TESTSAV_FIXBOX2);
    auto loaded_save_orig = gba_read_main_save(cast(const(ubyte)*) savfile_buf);
    auto loaded_save_dup = gba_read_main_save(cast(const(ubyte)*) savfile_buf);

    // read pc to struct
    auto pc_struct = gba_unpack_pc_data(loaded_save_orig);
    // writefln("pc: %s", pc_struct);
    // writefln("size of pc struct: %s", pc_struct.sizeof);

    // do something evil
    auto raw_fake_pc = gba_get_pc(loaded_save_dup);
    memset(raw_fake_pc, 0xAA, gba_box_data.GBA_BOX_DATA_SLICE1);

    // pack struct to pc
    gba_pack_pc_data(loaded_save_dup, &pc_struct);

    // ensure that they're the same
    auto loaded_save_orig_bin = loaded_save_orig.data[0..GBA_UNPACKED_SIZE];
    auto loaded_save_dup_bin = loaded_save_dup.data[0..GBA_UNPACKED_SIZE];
    // assert(*loaded_save_orig.data == *loaded_save_dup.data, "save file data is not equal");
    assert(loaded_save_orig_bin == loaded_save_dup_bin, "save file data is not equal");
}
