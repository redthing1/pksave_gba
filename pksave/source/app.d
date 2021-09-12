import std.stdio;
import std.file;
import std.path;
import std.conv;
import commandr;

import libspec;
import util;
import pokesave;

void main(string[] raw_args) {
	// dfmt off
	auto args = new Program("pksave", "1.0")
		.add(new Flag("v", null, "turns on more verbose output").name("verbose").repeating)
		.add(new Command("info")
			.add(new Argument("sav", "save file"))
			)
		.add(new Command("addmoney")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("money", "money to add"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("trade")
			.add(new Argument("source_sav", "source save file"))
			.add(new Argument("source_slot", "pokemon party slot"))
			.add(new Argument("receiver_sav", "receiver save file"))
			.add(new Argument("receiver_slot", "pokemon party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.parse(raw_args);

	args
		.on("info", (args) {
			// args.flag("verbose") works
			cmd_info(args);
		})
		.on("addmoney", (args) {
			cmd_addmoney(args);
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
}

void cmd_addmoney(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto out_sav = args.arg("out_sav");
	auto add_money = args.arg("money").to!uint;

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();
	writefln("adding money: %s", add_money);
	save.money = save.money + add_money;
	writefln("total money: %s", save.money);
	writefln("writing save: %s", out_sav);
	save.write_to(out_sav);
}

void cmd_trade(ProgramArgs args) {
	auto source_sav = args.arg("source_sav");
	auto receiver_sav = args.arg("receiver_sav");
	auto source_slot = args.arg("source_slot").to!uint;
	auto receiver_slot = args.arg("receiver_slot").to!uint;
	auto out_sav = args.arg("out_sav");

	writefln("loading source save: %s", source_sav);
	auto source_save = new PokeSave();
	source_save.read_from(source_sav);
	source_save.verify();
	writefln("loading receiver save: %s", receiver_sav);
	auto receiver_save = new PokeSave();
	receiver_save.read_from(receiver_sav);
	receiver_save.verify();

	writefln("transferring pokemon from source slot %s to receiver slot %s", source_slot, receiver_slot);
	// decrypt boxes

	// TODO: verify party integrity
	auto validity = receiver_save.verify_party();
	writefln("verifying party integrity: %s", validity ? "VALID" : "INVALID");

	writefln("writing save: %s", out_sav);
	receiver_save.write_to(out_sav);
}