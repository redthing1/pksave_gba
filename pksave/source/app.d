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
		.add(new Command("shine")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("slot", "party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("transfer")
			.add(new Argument("source_sav", "source save file"))
			.add(new Argument("source_slot", "pokemon party slot"))
			.add(new Argument("recv_sav", "receiver save file"))
			.add(new Argument("recv_slot", "pokemon party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("trade")
			.add(new Argument("sav1_in", "save 1 input"))
			.add(new Argument("sav1_slot", "save 1 party slot"))
			.add(new Argument("sav2_in", "save 2 input"))
			.add(new Argument("sav2_slot", "save 2 party slot"))
			.add(new Argument("sav1_out", "save 1 output"))
			.add(new Argument("sav2_out", "save 2 output"))
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
		.on("shine", (args) {
			cmd_shine(args);
		})
		.on("transfer", (args) {
			cmd_transfer(args);
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

		auto pock_sz = gba_get_pocket_size(save.loaded_save, pocket_id);
		writefln("  POCKET: %s (max: %s)", pocket_id, pock_sz);
		for (int j = 0; j < pock_sz; j++) {
			auto item = gba_get_pocket_item(save.loaded_save, pocket_id, j);
			if (item.amount == 0)
				continue;
			if (save.rom_loaded) {
				// detailed item info
				auto item_info = *save.rom.get_item_info(item.index);
				// writefln(item_info.toString());
				// assert(item.index == item_info.index,
				// 		"item index in save did not match item index in rom item table");
				writefln("    [%02d] NAME: %s, ID: %s (%s), COUNT: %s", j + 1,
						decode_gba_text(item_info.name.dup).strip(),
						item.index, item_info.index, item.amount);
			} else {
				writefln("    [%s] ID: %s, COUNT: %s", j + 1, item.index, item.amount);
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

void cmd_shine(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto slot = args.arg("slot").to!uint;
	auto out_sav = args.arg("out_sav");

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();

	writefln("selecting pkmn: %s", slot);
	auto pkmn = &save.party.pokemon[slot];
	pk3_decrypt(&pkmn.box);

	// make it shine
	auto shine1 = (pkmn.box.ot_id ^ pkmn.box.ot_sid);
	auto shine3 = pkmn.box.pid_low;
	ushort shiny_target = 0b1100_0000_0000_0000;
	auto shine_high_solve = (shine1 ^ shine3) ^ shiny_target;
	writefln("solved shiny equation: (%016b)", shine_high_solve);
	pkmn.box.pid_high = cast(ushort) shine_high_solve;

	// auto per = save.parse_personality(pkmn.box);
	// writefln("shiny: %s", per.shiny);

	pk3_encrypt(&pkmn.box);
	writefln("writing save: %s", out_sav);
	save.write_to(out_sav);
}

void cmd_transfer(ProgramArgs args) {
	writefln("> PKSAVE TRANSFER");

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

void cmd_trade(ProgramArgs args) {
	writefln("> PKSAVE TRADE");

	auto sav1_in = args.arg("sav1_in");
	auto sav1_slot = args.arg("sav1_slot").to!uint;
	auto sav1_out = args.arg("sav1_out");
	auto sav2_in = args.arg("sav2_in");
	auto sav2_slot = args.arg("sav2_slot").to!uint;
	auto sav2_out = args.arg("sav2_out");

	writefln("loading save 1: %s", sav1_in);
	auto save1 = new PokeSave();
	save1.read_from(sav1_in);
	save1.verify();
	writefln("loading save 2: %s", sav2_in);
	auto save2 = new PokeSave();
	save2.read_from(sav2_in);
	save2.verify();

	writefln("trading pokemon between sav1 slot %s and sav2 slot %s", sav1_slot, sav2_slot);
	// decrypt boxes
	auto pkmn1 = &save1.party.pokemon[sav1_slot];
	auto pkmn2 = &save2.party.pokemon[sav2_slot];
	pk3_decrypt(&pkmn1.box);
	pk3_decrypt(&pkmn2.box);
	// dereference and store copy of pkmn data
	auto pkmn1_copy = *pkmn1;
	auto pkmn2_copy = *pkmn2;
	writeln("TRANSACTION");
	writeln("  UPLOAD 1->2:");
	writefln("    %s (L. %s) (from save 1) is being transformed into data and uploaded!",
			decode_gba_text(pkmn1_copy.box.nickname), pkmn1_copy.party.level);
	pkmn2.box = pkmn1_copy.box;
	pkmn2.party = pkmn1_copy.party;
	writefln("    On the other end (save 2), it's %s (L. %s)!",
			decode_gba_text(pkmn2.box.nickname), pkmn2.party.level);
	writeln("  UPLOAD 2->1:");
	writefln("    %s (L. %s) (from save 2) is being transformed into data and uploaded!",
			decode_gba_text(pkmn2_copy.box.nickname), pkmn2_copy.party.level);
	pkmn1.box = pkmn2_copy.box;
	pkmn1.party = pkmn2_copy.party;
	writefln("    On the other end (save 1), it's %s (L. %s)!",
			decode_gba_text(pkmn1.box.nickname), pkmn1.party.level);
	pk3_encrypt(&pkmn2.box);
	pk3_encrypt(&pkmn1.box);

	writeln("TRADE SUMMARY:");
	writefln("  Traded %s's '%s' (L. %s) for %s's '%s' (L. %s)! Take care of them!",
			decode_gba_text(save1.trainer.name),
			decode_gba_text(pkmn1_copy.box.nickname), pkmn1_copy.party.level, decode_gba_text(save2.trainer.name),
			decode_gba_text(pkmn2_copy.box.nickname), pkmn2_copy.party.level);

	// verify party integrity
	writeln("VERIFY:");
	auto validity1 = save1.verify_party();
	writefln("  SAV1 INTEGRITY: %s", validity1 ? "VALID" : "INVALID");
	auto validity2 = save2.verify_party();
	writefln("  SAV2 INTEGRITY: %s", validity2 ? "VALID" : "INVALID");

	writefln("writing save 1: %s", sav1_out);
	save1.write_to(sav1_out);
	writefln("writing save 2: %s", sav2_out);
	save2.write_to(sav2_out);
}
