import std.stdio;
import std.file;
import std.path;
import std.conv;
import std.string;
import std.traits;
import commandr;

import libspec;
import util;
import pokesave;
import pokegame;

void main(string[] raw_args) {
	// dfmt off
	auto args = new Program("pksave", "1.0")
		.add(new Flag("v", null, "turns on more verbose output").name("verbose").repeating)
		.add(new Command("info")
			.add(new Argument("sav", "save file"))
			.add(new Argument("rom", "rom file").optional.defaultValue("NONE"))
			)
		.add(new Command("addmoney")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("money", "money to add"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("verify")
			.add(new Argument("sav", "save file"))
			)
		.add(new Command("trade")
			.add(new Argument("source_sav", "source save file"))
			.add(new Argument("source_slot", "pokemon party slot"))
			.add(new Argument("recv_sav", "receiver save file"))
			.add(new Argument("recv_slot", "pokemon party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.parse(raw_args);

	args
		.on("info", (args) {
			// args.flag("verbose") works
			cmd_info(args);
		})
		.on("verify", (args) {
			cmd_verify(args);
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
	auto rom_path = args.arg("rom");

	writefln("> PKSAVE INFO: %s", sav_path);

	auto save = new PokeSave();
	save.read_from(sav_path);
	save.verify();

	if (rom_path != "NONE") {
		writefln("> ROM: %s", rom_path);
		save.load_companion_rom(rom_path);
	}

	writeln("SAVE");
	writefln("  TYPE: %s", save.loaded_save.type);
	if (save.rom_loaded) {
		writefln("  ROM: %s", save.rom.rom_type);
	}
	auto key1 = gba_get_security_key(
			save.loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY_OFFSET).key;
	auto key2 = gba_get_security_key(
			save.loaded_save.data + gba_game_detect.GBA_FRLG_SECURITY_KEY2_OFFSET).key;
	auto key_match = key1 == key2 ? "VALID" : "INVALID";
	writefln("  KEYS: %s (%s, %s)", key_match, key1, key2);
	writefln("  POKEBLOCK: %s", pk3_t.sizeof);
	writefln("    TRAIN: %s", gba_trainer_t.sizeof);
	writefln("    PARTY: %s", pk3_party_t.sizeof);
	writefln("    BOX: %s", pk3_box_t.sizeof);
	writefln("    SPECIES: %s", PkmnROMSpecies.sizeof);
	writefln("    ITEM: %s", PkmnROMItem.sizeof);

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

		// main info
		writefln("  NAME: %s (raw:%s)", decode_gba_text(box.nickname), format_hex(box.nickname));
		writefln("    SPECIES: 0x%04X", box.species);
		// writefln("    TRAINER: %s", decode_gba_text(box.ot_name));
		writefln("    LEVEL: %s", pkmn.party.level);
		writefln("    STATS: %s", pkmn.party.stats);
		writefln("    IVS: %s", box.iv);
		writefln("    EVS: %s", box.ev);

		// species info
		auto species_info = save.rom.get_species_info(box.species);
		writefln("    SPECIES: (%s)", species_info.toString());

		// personality info
		auto personality = save.parse_personality(box);
		writefln("    PERSONALITY: (%s)", personality);

		// verify checksum (by recomputing)
		ushort local_checksum = pk3_checksum(cast(const(ubyte*)) box.block,
				pk3_encryption.PK3_DATA_SIZE);
		auto cksum_validity = (box_cksum == local_checksum) ? "VALID" : "INVALID";
		writefln("    CKSUM: 0x%04X (%s) (orig: 0x%04X)", local_checksum,
				cksum_validity, box_cksum);
	}
	writeln("ITEMS");
	auto num_pockets = EnumMembers!gba_item_pocket_t.length;
	writefln("  POCKETS: %s", num_pockets);
	// print party members
	for (int i = 0; i < num_pockets; i++) {
		auto pocket_id = i.to!gba_item_pocket_t;

		writefln("  POCKET: %s", pocket_id);
		auto pock_sz = gba_get_pocket_size(save.loaded_save, pocket_id);
		for (int j = 0; j < pock_sz; j++) {
			auto item = gba_get_pocket_item(save.loaded_save, pocket_id, j);
			if (item.amount == 0)
				continue;
			if (save.rom_loaded) {
				// detailed item info
				auto item_info = *save.rom.get_item_info(item.index);
				// writefln(item_info.toString());
				writefln("    NAME: %s, ID: %s (%s), COUNT: %s", decode_gba_text(item_info.name.dup).strip(), item.index, item_info.index, item.amount);
			} else {
				writefln("    ID: %s, COUNT: %s", item.index, item.amount);
			}
		}
	}

}

void cmd_verify(ProgramArgs args) {
	auto in_sav = args.arg("sav");

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	writefln("verifying save headers");
	save.verify();
	writefln("verifying pkmn in party");
	save.verify_party();
	writefln("save is VALID!");
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
	auto recv_sav = args.arg("recv_sav");
	auto source_slot = args.arg("source_slot").to!uint;
	auto recv_slot = args.arg("recv_slot").to!uint;
	auto out_sav = args.arg("out_sav");

	writefln("loading source save: %s", source_sav);
	auto source_save = new PokeSave();
	source_save.read_from(source_sav);
	source_save.verify();
	writefln("loading receiver save: %s", recv_sav);
	auto recv_save = new PokeSave();
	recv_save.read_from(recv_sav);
	recv_save.verify();

	writefln("transferring pokemon from source slot %s to receiver slot %s", source_slot, recv_slot);
	// decrypt boxes
	auto source_pkmn = &source_save.party.pokemon[source_slot];
	auto source_box_copy = source_pkmn.box;
	pk3_decrypt(&source_box_copy);
	auto recv_pkmn = &recv_save.party.pokemon[recv_slot];
	pk3_decrypt(&recv_pkmn.box);
	writefln("%s (L. %s) is being transformed into data and uploaded!",
			decode_gba_text(source_box_copy.nickname), source_pkmn.party.level);
	recv_pkmn.party = source_pkmn.party;
	recv_pkmn.box = source_box_copy;
	writefln("On the other end, it's %s (L. %s)!",
			decode_gba_text(recv_pkmn.box.nickname), recv_pkmn.party.level);
	pk3_encrypt(&recv_pkmn.box);

	// verify party integrity
	auto validity = recv_save.verify_party();
	writefln("verifying recv party integrity: %s", validity ? "VALID" : "INVALID");

	writefln("writing save: %s", out_sav);
	recv_save.write_to(out_sav);
}
