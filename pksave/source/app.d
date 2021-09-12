import std.stdio;
import libspec;
import std.file;
import std.path;
import commandr;

import util;
import pokesave;

void main(string[] raw_args) {
	// dfmt off
	auto args = new Program("pksave", "1.0")
		.add(new Flag("v", null, "turns on more verbose output").name("verbose").repeating)
		.add(new Command("info")
			.add(new Argument("sav", "save file"))
			)
		.add(new Command("trade")
			.add(new Argument("source_sav", "source save file"))
			.add(new Argument("receiver_sav", "receiver save file"))
			)
		.parse(raw_args);

	args
		.on("info", (args) {
			// args.flag("verbose") works
			cmd_info(args);
		})
		.on("trade", (args) {
			cmd_trade(args);
		});
	// dfmt on
}

void cmd_info(ProgramArgs args) {
	auto sav_path = args.arg("sav");
	writefln("> PKSAVE INFO: %s", sav_path);
	
	auto save = new PokeSave();
	save.read_from(sav_path);
	save.verify();

	writeln("SAVE");
	writefln("  TYPE: %s", save.loaded_save.type);
	auto key1 = gba_get_security_key(save.loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY_OFFSET).key;
	auto key2 = gba_get_security_key(save.loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY2_OFFSET).key;
	auto key_match = key1 == key2 ? "VALID" : "INVALID";
	writefln("  KEYS: %s (%s, %s)", key_match, key1, key2);
	writefln("  POKEBLOCK: %s", pk3_t.sizeof);
	writefln("    TRAIN: %s", gba_trainer_t.sizeof);
	writefln("    PARTY: %s", pk3_party_t.sizeof);
	writefln("    BOX: %s", pk3_box_t.sizeof);

	auto trainer = save.trainer;
	writeln("TRAINER");
	writefln("  NAME: %s (raw:%s)", decode_gba_text(trainer.name), format_hex(trainer.name));
	writefln("  GENDER: %s", trainer.gender == 0 ? "M" : "F");
	writefln("  PLAYTIME: %s", gba_time_to_string(trainer.time_played));

	writeln("ITEMS");
	writefln("  MONEY: %s", gba_get_money(save.loaded_save));

	auto party = save.party;
	if (party == null) {
		writeln("failed to get party");
	}
	writeln("PARTY");
	writefln("  MEMBERS: %s", party.size);
	// print party members
	for (int i = 0; i < party.size; i++) {
		auto pkmn = party.pokemon[i];
		// decrypt local copy of box
		auto box = pkmn.box;
		auto box_cksum = box.checksum;
		pk3_decrypt(&box);
		writefln("  NAME: %s (raw:%s)", decode_gba_text(box.nickname), format_hex(box.nickname));
		writefln("    SPECIES: 0x%04X", box.species);
		// writefln("    TRAINER: %s", decode_gba_text(box.ot_name));
		writefln("    LEVEL: %s", pkmn.party.level);
		writefln("    STATS: %s", pkmn.party.stats);
		writefln("    IVS: %s", box.iv);
		writefln("    EVS: %s", box.ev);
		// verify checksum (by recomputing)
		ushort local_checksum = pk3_checksum(cast(const(ubyte*)) box.block,
				pk3_encryption.PK3_DATA_SIZE);
		auto cksum_validity = (box_cksum == local_checksum) ? "VALID" : "INVALID";
		writefln("    CKSUM: 0x%04X (%s) (orig: 0x%04X)", local_checksum,
				cksum_validity, box_cksum);
	}

	// try modding the save

	// set money to value
	save.money = 10_000;

	// change 2nd pokemon to a squirtle
	auto pkmn1 = &party.pokemon[1];
	pk3_decrypt(&pkmn1.box);
	pkmn1.box.species = 0x0007; // squirtle
	pk3_encrypt(&pkmn1.box);

	// now try to write the save to _pks.sav
	auto output_sav_path = std.path.stripExtension(sav_path) ~ "_pks.sav";

	writefln("writing new save to: %s", output_sav_path);
	save.write_to(output_sav_path);
}

void cmd_trade(ProgramArgs args) {
}