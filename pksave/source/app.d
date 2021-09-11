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

	writeln("SAVE");
	writefln("  TYPE: %s", loaded_save.type);
	writefln("  KEY: %s", gba_get_security_key(loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY_OFFSET).key);

	auto trainer = gba_get_trainer(loaded_save);
	writeln("TRAINER");
	writefln("  NAME: %s", decode_gba_text(trainer.name));
	writefln("  GENDER: %s", trainer.gender == 0 ? "M" : "F");
	writefln("  PLAYTIME: %s", gba_time_to_string(trainer.time_played));
	
	writeln("ITEMS");
	writefln("  MONEY: %s", gba_get_money(loaded_save));

	auto party = gba_get_party(loaded_save);
	writeln("PARTY");
	writeln(party);
	// writefln("  MEMBERS: %s", party.size);
}
