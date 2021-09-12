import std.stdio;
import libspec;
import std.file;
import std.path;

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
	writefln("  KEY1: %s", gba_get_security_key(
			loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY_OFFSET).key);
	writefln("  KEY2: %s", gba_get_security_key(
			loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY2_OFFSET).key);
	writefln("  POKEBLOCK: %s", pk3_t.sizeof);
	writefln("    TRAIN: %s", gba_trainer_t.sizeof);
	writefln("    PARTY: %s", pk3_party_t.sizeof);
	writefln("    BOX: %s", pk3_box_t.sizeof);

	auto trainer = gba_get_trainer(loaded_save);
	writeln("TRAINER");
	writefln("  NAME: %s", decode_gba_text(trainer.name));
	writefln("  GENDER: %s", trainer.gender == 0 ? "M" : "F");
	writefln("  PLAYTIME: %s", gba_time_to_string(trainer.time_played));

	writeln("ITEMS");
	writefln("  MONEY: %s", gba_get_money(loaded_save));

	auto party = gba_get_party(loaded_save);
	if (party == null) {
		writeln("failed to get party");
	}
	writeln("PARTY");
	writefln("  MEMBERS: %s", party.size);
	// print party members
	for (int i = 0; i < party.size; i++) {
		auto pkmn = party.pokemon[i];
		writefln("  NAME: %s", decode_gba_text(pkmn.box.nickname));
		writefln("    SPECIES: 0x%04x", pkmn.box.species);
		// writefln("    TRAINER: %s", decode_gba_text(pkmn.box.ot_name));
		writefln("    LEVEL: %s", pkmn.party.level);
		writefln("    STATS: %s", pkmn.party.stats);
		// writefln("    IVS: %s", pkmn.box.iv);
		// writefln("    EVS: %s", pkmn.box.ev);		
	}

	// try modding it
	gba_set_money(loaded_save, 10_000);

	// now try to write the save to _pks.sav
	auto output_sav_path = std.path.stripExtension(sav_path) ~ "_pks.sav";

	writefln("writing new save to: %s", output_sav_path);
	// copy loaded save buffer
	auto output_sav_data = new ubyte[](savfile_data.length);
	output_sav_data[0 .. $] = savfile_data[0 .. $]; // copy buffer
	// now save
	gba_write_main_save(cast(ubyte*) output_sav_data, loaded_save);
	std.file.write(output_sav_path, output_sav_data);
}
