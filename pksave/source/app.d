import std.stdio;
import libspec;
import std.file;

import util;

void main(string[] args) {
	writeln("PKSAVE");

	auto sav_path = args[1];
	writefln("save path: %s", sav_path);
	auto savfile_data = cast(ubyte[]) std.file.read(sav_path);

	// try loading the save
	auto loaded_save = gba_read_main_save(cast(const(ubyte)*) savfile_data);

	auto trainer = gba_get_trainer(loaded_save);	
	writefln("trainer name: %s", decode_gba_text(trainer.name));
}
