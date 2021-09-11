import std.stdio;
import libspec;
import std.file;

import util;

void main(string[] args) {
	writeln("> PKSAVE");

	auto sav_path = args[1];
	// writefln("save path: %s", sav_path);
	auto savfile_data = cast(ubyte[]) std.file.read(sav_path);

	// try loading the save
	auto loaded_save = gba_read_main_save(cast(const(ubyte)*) savfile_data);

	auto trainer = gba_get_trainer(loaded_save);
	writeln("TRAINER");
	writefln("  NAME: %s", decode_gba_text(trainer.name));
	writefln("  GENDER: %s", trainer.gender == 0 ? "M" : "F");
	writefln("  PLAYTIME: %s", gba_time_to_string(trainer.time_played));
	writeln("ITEMS");
	writefln("  MONEY: %s", gba_get_money(loaded_save));
}
