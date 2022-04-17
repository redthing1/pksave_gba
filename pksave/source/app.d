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
import dump;

void main(string[] raw_args) {
	// dfmt off
	auto args = new Program("pksave", "1.0")
		.add(new Flag("v", null, "turns on more verbose output").name("verbose").repeating)
		.add(new Command("info", "show detailed info on a save file. pass rom as well for more details")
			.add(new Argument("sav", "save file"))
			.add(new Argument("rom", "rom file").optional.defaultValue(""))
			)
		.add(new Command("dumprom", "dump info tables from a rom")
			.add(new Argument("rom", "rom file"))
			)
		.add(new Command("pkmn", "dump all pokemon in save file")
			.add(new Argument("sav", "save file"))
			.add(new Argument("rom", "rom file").optional.defaultValue(""))
			)
		.add(new Command("verify", "verify checksum validity in your party (prevent bad eggs)")
			.add(new Argument("sav", "save file"))
			)
		.add(new Command("dumpsav", "dump raw save data struct")
			.add(new Argument("sav", "save file"))
			.add(new Argument("out", "output file"))
			)
		.add(new Command("symbolscan", "scan a rom to try to find symbols")
			.add(new Argument("rom", "rom file"))
			)
		.add(new Command("addmoney", "add money to your save")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("money", "money to add"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("touch", "read and write a save to verify correct processing")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("shine", "make a pokemon in your party shiny")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("slot", "party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("maxiv", "set pokemon iv to max")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("slot", "party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("freeze", "freeze a pokemon in your party")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("slot", "party slot"))
			.add(new Argument("out", "output file"))
			)
		.add(new Command("dumpcube", "dump info about a frozen pokemon")
			.add(new Argument("in_pkmn", "input pkmn file"))
			)
		.add(new Command("melt", "restore a frozen pokemon to your party")
			.add(new Argument("in_sav", "input save file"))
			.add(new Argument("slot", "party slot"))
			.add(new Argument("in_pkmn", "input pkmn file"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("transfer", "transfer a pokemon from one save to another, but leaving the original intact")
			.add(new Argument("source_sav", "source save file"))
			.add(new Argument("source_slot", "pokemon party slot"))
			.add(new Argument("recv_sav", "receiver save file"))
			.add(new Argument("recv_slot", "pokemon party slot"))
			.add(new Argument("out_sav", "output save file"))
			)
		.add(new Command("trade", "bidirectional pokemon trade between two saves.")
			.add(new Argument("sav1_in", "save 1 input"))
			.add(new Argument("sav1_slot", "save 1 party slot"))
			.add(new Argument("sav2_in", "save 2 input"))
			.add(new Argument("sav2_slot", "save 2 party slot"))
			.add(new Argument("sav1_out", "save 1 output").optional.defaultValue(""))
			.add(new Argument("sav2_out", "save 2 output").optional.defaultValue(""))
			.add(new Flag("s", "remap", "remap data using names").full("remap"))
			.add(new Option(null, "rom1", "rom for save 1"))
			.add(new Option(null, "rom2", "rom for save 2"))
			)
		.parse(raw_args);

	args
		.on("info", (args) {
			// args.flag("verbose") works
			cmd_info(args);
		})
		.on("dumprom", (args) {
			cmd_dumprom(args);
		})
		.on("pkmn", (args) {
			cmd_pkmn(args);
		})
		.on("verify", (args) {
			cmd_verify(args);
		})
		.on("dumpsav", (args) {
			cmd_dumpsav(args);
		})
		.on("symbolscan", (args) {
			cmd_symbolscan(args);
		})
		.on("addmoney", (args) {
			cmd_addmoney(args);
		})
		.on("touch", (args) {
			cmd_touch(args);
		})
		.on("shine", (args) {
			cmd_shine(args);
		})
		.on("maxiv", (args) {
			cmd_maxiv(args);
		})
		.on("freeze", (args) {
			cmd_freeze(args);
		})
		.on("dumpcube", (args) {
			cmd_dumpcube(args);
		})
		.on("melt", (args) {
			cmd_melt(args);
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

	if (rom_path != "") {
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

	assert(pk3_t.sizeof == 100);
	assert(gba_trainer_t.sizeof == 22);
	assert(pk3_party_t.sizeof == 20);
	assert(pk3_box_t.sizeof == 80);
	assert(PkmnROMSpecies.sizeof == 28);
	assert(PkmnROMItem.sizeof == 44);

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
		auto dump_str = dump_prettyprint_pkmn(save, pkmn);
		writefln("%s", dump_str);
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

void cmd_dumprom(ProgramArgs args) {
	auto in_rom = args.arg("rom");

	writefln("loading rom: %s", in_rom);
	auto rom = new PkmnROM();
	rom.read_from(in_rom);
	rom.verify();
	writefln("ROM");
	writefln("INFO");
	writefln(" TYPE: %s", rom.rom_type);
	writefln("ITEMS");

	// dump all items
	auto item_tbl = rom.get_item_info_table();
	for (int i = 0; i < item_tbl.length; i++) {
		auto item = &item_tbl[i];
		writefln(" [%03d] (0x%04x) ITEM: %s", i, i, decode_gba_text(item.name).strip());
	}

	// dump all species
	auto spec_tbl = rom.get_species_basestats_table();
	for (int i = 0; i < spec_tbl.length; i++) {
		auto species = spec_tbl[i];
		auto species_name = decode_gba_text(rom.get_species_name(i)).strip();
		writefln(" [%03d] (0x%04x) SPECIES: (%s) %s", i, i, species_name, species);
	}

	// dump all move names
	for (int i = 0; i < rom.num_moves; i++) {
		auto move_name = decode_gba_text(rom.get_move_name(i)).strip();
		writefln(" [%03d] (0x%04x) MOVE: %s", i, i, move_name);
	}
	
	// dump all learnsets
	void dump_learnsets(T)(T[] learnsets_tbl) {
		writefln("LEARNSETS");
		for (auto i = 0; i < learnsets_tbl.length; i++) {
			auto species_learnset = learnsets_tbl[i];

			auto species_id = i;
			auto species_name = decode_gba_text(rom.get_species_name(species_id)).strip();

			writefln(" LEARNSET: %s (0x%04x)", species_name, species_id);
			for (auto j = 0; j < species_learnset.moves.length; j++) {
				auto lvlup_move = species_learnset.moves[j];
				auto move_name = decode_gba_text(rom.get_move_name(lvlup_move.move)).strip();

				writefln("  LEVEL: %s, MOVE: %s", lvlup_move.level, move_name);
			}
		}
	}
	auto learnsets_tbl_st = rom.get_learnsets();
	import std.sumtype: match;

	learnsets_tbl_st.match!(
		(PkmnROMLearnsets16 ls) => dump_learnsets(ls),
		(PkmnROMLearnsets32 ls) => dump_learnsets(ls),
	);
}

void cmd_pkmn(ProgramArgs args) {
	auto sav_path = args.arg("sav");
	auto rom_path = args.arg("rom");

	auto save = new PokeSave();
	save.read_from(sav_path);
	save.verify();

	if (rom_path != "") {
		writefln("> ROM: %s", rom_path);
		save.load_companion_rom(rom_path);
	}

	auto party = save.party;
	if (party == null) {
		writeln("failed to get party");
	}
	auto pc = save.unpack_pc_data();
	// if (pc == null) {
	// 	writeln("failed to get pc");
	// }

	// all pokemon in party
	writeln("PARTY");
	writefln("  MEMBERS: %s", party.size);
	// print party members
	for (int i = 0; i < party.size; i++) {
		auto pkmn = party.pokemon[i];
		auto dump_str = dump_prettyprint_pkmn(save, pkmn.box);
		writefln("%s", dump_str);
	}

	// all pokemon in pc boxes
	writefln("PC BOXES (current: %s)", pc.current_box);
	for (auto i = 0; i < GBA_BOX_COUNT; i++) {
		auto pc_box = &pc.box[i];
		auto pc_box_name = decode_gba_text(pc.name[i].dup).strip();
		writefln("PC BOX #%s (%s)", i + 1, pc_box_name);
		for (auto j = 0; j < GBA_POKEMON_IN_BOX; j++) {
			auto box_pkmn_ptr = &pc_box.pokemon[j];
			auto box_pkmn = pc_box.pokemon[j];

			if (box_pkmn.species == 0) {
				// no pokemon in this slot
				continue;
			}

			// // dump raw bytes
			// // auto raw_pokeblock_d = box_pkmn.block[3];
			// writefln("pk3_box raw offset: 0x%04x", (cast(ulong) (box_pkmn_ptr) - cast(ulong) (save.loaded_save.data)));
			// for (auto l = 0; l < 4; l++) {
			// 	auto pkblk = box_pkmn.block[l];
			// 	writef("block: #%s: ", l);
			// 	for (auto k = 0; k < pkblk.length; k++) {
			// 		writef("%02x ", pkblk[k]);
			// 	}
			// 	writeln();
			// }

			writefln(" SLOT: #%s", j + 1);
			auto dump_str = dump_prettyprint_pkmn(save, box_pkmn);
			writefln("%s", dump_str);
		}
	}
	// writeln("PC");
	// writefln("  MEMBERS: %s", pc.size);
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

void cmd_dumpsav(ProgramArgs args) {
	auto in_sav = args.arg("sav");
	auto out_bin = args.arg("out");

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();

	writefln("dumping raw save data");
	save.write_raw_dump_to(out_bin);
}

void cmd_symbolscan(ProgramArgs args) {
	import std.algorithm.searching;
	import std.algorithm.iteration;
	import std.range;
	import std.array;

	auto in_rom = args.arg("rom");

	writefln("loading rom: %s", in_rom);
	auto rom = new PkmnROM();
	rom.read_from(in_rom);
	// rom.verify(); // do not verify!

	writefln("scanning rom for symbols");

	ulong[] search_rom(OffsetFinder finder) {
		auto raw_matches = KMP!(ubyte[], ubyte[])(rom.rom_buf, finder.match_sequence).array;
		ulong[] match_offsets = raw_matches.map!(x => x + finder.leading_offset).array;

		return match_offsets;
	}

	void show_search_results(ulong[] results) {
		writefln("  results: %s", results.length);
		foreach (res; results) {
			writefln("   0x%04X", res);
		}
		if (results.length == 0) {
			writefln("   no results! look manually.");
		}
		if (results.length == 1) {
			writefln("   exactly one result! good candidate.");
		}
	}

	enum search_queue = [
			"gBaseStats": SPECIES_TABLE_FINDERS,
			"gItems": ITEM_TABLE_FINDERS,
			"gSpeciesNames": SPECIES_NAME_FINDERS,
			"gTypeNames": TYPE_NAME_FINDERS,
			"gBattleMoves": MOVE_TABLE_FINDERS,
			"gMoveNames": MOVE_NAME_FINDERS,
			"sBulbasaurLevelUpLearnset": BULBASAUR_LEARNSET_FINDERS,
		];

	struct GoodResult {
		string symbol_name;
		ulong offset;

		string toString() const {
			return format("%20s: 0x%04X", symbol_name, offset);
		}
	}

	GoodResult[] good_results;

	// auto searches
	static foreach (sym_name, sym_finders; search_queue) {
		// auto sym_name = key;
		// auto sym_finders = search_queue[key];

		writefln("search: %s", sym_name);
		foreach (i, finder; sym_finders) {
			writefln(" checking pattern #%s: %s", i, finder.name);
			auto search_results = search_rom(finder);
			show_search_results(search_results);
			if (search_results.length == 1) {
				good_results ~= GoodResult(sym_name, search_results[0]);
			}
		}
	}

	// manual searches
	writefln("search: gLevelUpLearnsets");
	OffsetFinder[] learnset_finders;
	enum bulbasaur_learnset_symbol = "sBulbasaurLevelUpLearnset";
	if (good_results.canFind!(x => x.symbol_name == bulbasaur_learnset_symbol)) {
		// we know where the bulbasaur learnset is

		// build search patterns

		// consecutive pointers
		auto bulbasaur_addr = good_results.find!(
			x => x.symbol_name == bulbasaur_learnset_symbol).front.offset;
		ubyte[] bulbasaur_gba_ptr = [
			((bulbasaur_addr >> 0) & 0xff), // least significant byte
			((bulbasaur_addr >> 8) & 0xff), // byte 2
			((bulbasaur_addr >> 16) & 0xff), // byte 3
			// ((bulbasaur_addr >> 24) > 0) ? 0x08 : 0x00, // byte 4 (msb)
			0x08, // gba memory map makes address most significant byte 0x08
		];
		learnset_finders ~= OffsetFinder("Consecutive Bulbasaur Pointers", 0, bulbasaur_gba_ptr ~ bulbasaur_gba_ptr);

		foreach (i, finder; learnset_finders) {
			writefln(" checking pattern #%s: %s", i, finder.name);
			auto search_results = search_rom(finder);
			show_search_results(search_results);
			if (search_results.length == 1) {
				good_results ~= GoodResult("gLevelUpLearnsets", search_results[0]);
			}
		}
	} else {
		writefln(" no bulbasaur learnset availble. can't search for gLevelUpLearnsets");
	}

	writefln("summary:");
	writefln(" good results: %s", good_results.length);
	foreach (res; good_results) {
		writefln("  %s", res);
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

void cmd_touch(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto out_sav = args.arg("out_sav");

	import std.random : choice;

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();

	writefln("writing save: %s", out_sav);
	save.write_to(out_sav);
}

void cmd_shine(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto slot = args.arg("slot").to!uint;
	auto out_sav = args.arg("out_sav");

	import std.random : choice;

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
	// pick target
	ushort shiny_target = cast(ushort)(0b0000_0000_0000_0000) + cast(ubyte)([
		0, 1, 2, 3, 4, 5, 6, 7
	].choice());
	auto shine_high_solve = (shine1 ^ shine3) ^ shiny_target;
	writefln("solved shiny equation: (%016b)", shine_high_solve);
	pkmn.box.pid_high = cast(ushort) shine_high_solve;

	auto per = save.parse_personality(pkmn.box);
	writefln("shiny: %s", per.shiny);

	pk3_encrypt(&pkmn.box);
	writefln("writing save: %s", out_sav);
	save.write_to(out_sav);
}

void cmd_maxiv(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto slot = args.arg("slot").to!uint;
	auto out_sav = args.arg("out_sav");

	import std.random : choice;

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();

	writefln("selecting pkmn: %s", slot);
	auto pkmn = &save.party.pokemon[slot];
	pk3_decrypt(&pkmn.box);

	// make its ivs max
	pkmn.box.iv.hp = 31;
	pkmn.box.iv.atk = 31;
	pkmn.box.iv.def = 31;
	pkmn.box.iv.spd = 31;
	pkmn.box.iv.satk = 31;
	pkmn.box.iv.sdef = 31;

	// print new IVs
	writefln("new IVs: %s", pkmn.box.iv);

	pk3_encrypt(&pkmn.box);
	writefln("writing save: %s", out_sav);
	save.write_to(out_sav);
}

void cmd_freeze(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto slot = args.arg("slot").to!uint;
	auto out_file = args.arg("out");

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();

	writefln("selecting pkmn: %s", slot);
	auto pkmn = &save.party.pokemon[slot];
	pk3_decrypt(&pkmn.box);

	writefln("crushing %s (L. %s) (checksum: 0x%04x) into bytes.",
		decode_gba_text(pkmn.box.nickname), pkmn.party.level, pkmn.box.checksum);
	pk3_encrypt(&pkmn.box); // re-encrypt
	auto pkmn_pk3_copy = *pkmn;
	auto pkmn_buf_raw = cast(ubyte*)(cast(void*)(&pkmn_pk3_copy));
	ubyte[100] out_pkmn_buf;
	for (int i = 0; i < out_pkmn_buf.length; i++) {
		out_pkmn_buf[i] = pkmn_buf_raw[i];
	}

	writefln("writing compacted pkmn to %s", out_file);
	std.file.write(out_file, out_pkmn_buf);
}

void cmd_dumpcube(ProgramArgs args) {
	auto in_pkmn_file = args.arg("in_pkmn");

	auto pkmn_buf = std.file.read(in_pkmn_file);
	writefln("read crushed pkmn (%s bytes) from: %s", pkmn_buf.length, in_pkmn_file);
	auto pkmn_pk3 = cast(pk3_t*)(cast(void*) pkmn_buf);

	writefln("decrypting box with checksum: 0x%04x", pkmn_pk3.box.checksum);
	pk3_decrypt(&(*pkmn_pk3).box);

	writefln("inside the pkmn cube was: %s (L. %s)",
		decode_gba_text(pkmn_pk3.box.nickname), pkmn_pk3.party.level);
}

void cmd_melt(ProgramArgs args) {
	auto in_sav = args.arg("in_sav");
	auto slot = args.arg("slot").to!uint;
	auto out_sav = args.arg("out_sav");
	auto in_pkmn_file = args.arg("in_pkmn");

	writefln("loading save: %s", in_sav);
	auto save = new PokeSave();
	save.read_from(in_sav);
	save.verify();

	auto pkmn_buf = std.file.read(in_pkmn_file);
	writefln("melting frozen and crushed pkmn (%s bytes) from: %s", pkmn_buf.length, in_pkmn_file);
	auto pkmn_pk3 = cast(pk3_t*)(cast(void*) pkmn_buf);

	writefln("decrypting box with checksum: 0x%04x", pkmn_pk3.box.checksum);
	pk3_decrypt(&(*pkmn_pk3).box);

	writefln("inside the pkmn cube was: %s (L. %s)",
		decode_gba_text(pkmn_pk3.box.nickname), pkmn_pk3.party.level);

	auto slot_pkmn = &save.party.pokemon[slot];
	writefln("placing: %s into slot %s", decode_gba_text(pkmn_pk3.box.nickname), slot);
	slot_pkmn.box = pkmn_pk3.box;
	slot_pkmn.party = pkmn_pk3.party;
	pk3_encrypt(&slot_pkmn.box);

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
	auto should_remap = args.flag("remap");
	auto rom1_in = args.option("rom1");
	auto rom2_in = args.option("rom2");

	if (should_remap && (!rom1_in || !rom2_in)) {
		writefln("ERROR: --remap-species requires --rom1 and --rom2");
		return;
	}

	if (sav1_out == "")
		sav1_out = sav1_in;
	if (sav2_out == "")
		sav2_out = sav2_in;

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

	writeln("CHECK");
	// ensure neither slot is empty
	if (pkmn1.party.level == 0 || pkmn1.box.nickname[0] == 0 || sav1_slot >= save1.party.size) {
		// invalid
		writefln("  save 1 slot %s is INVALID", sav1_slot);
		return;
	}
	if (pkmn2.party.level == 0 || pkmn2.box.nickname[0] == 0 || sav2_slot >= save2.party.size) {
		// invalid
		writefln("  save 2 slot %s is INVALID", sav2_slot);
		return;
	}
	writeln("  SLOTS ARE VALID");

	if (should_remap) {
		// remap species enabled
		writefln("REMAP SPECIES");

		// load and verify both roms
		auto rom1 = new PkmnROM();
		rom1.read_from(rom1_in);
		rom1.verify();

		auto rom2 = new PkmnROM();
		rom2.read_from(rom2_in);
		rom2.verify();

		string clean_name(ubyte[] data) {
			import std.string;

			return cast(string) decode_gba_text(data).strip.toLower;
		}

		// look up species names for the pokemon in corresponding roms
		auto species1_name = clean_name(rom1.get_species_name(pkmn1_copy.box.species));
		auto species2_name = clean_name(rom2.get_species_name(pkmn2_copy.box.species));

		writefln(" NAMES");
		writefln("  species 1: %s (0x%04x)", species1_name, pkmn1_copy.box.species);
		writefln("  species 2: %s (0x%04x)", species2_name, pkmn2_copy.box.species);

		long rom1_candidate_spec2 = -1;
		long rom2_candidate_spec1 = -1;

		// now search the other rom to find a matching species name
		for (auto i = 0; i < rom1.num_species; i++) {
			auto rom1_scan_name = clean_name(rom1.get_species_name(i));
			if (rom1_scan_name == species2_name) {
				// found a match
				writefln("  found candidate (0x%04x) in rom 1 for species 2: %s", i, rom1_scan_name);
				rom1_candidate_spec2 = i;
				break;
			}
		}

		for (auto i = 0; i < rom2.num_species; i++) {
			auto rom2_scan_name = clean_name(rom2.get_species_name(i));
			if (rom2_scan_name == species1_name) {
				// found a match
				writefln("  found candidate (0x%04x) in rom 2 for species 1: %s", i, rom2_scan_name);
				rom2_candidate_spec1 = i;
				break;
			}
		}

		if (rom1_candidate_spec2 < 0 || rom2_candidate_spec1 < 0) {
			// no match found
			writefln("  could not find matching species.");
			return;
		}

		// now we need to hack the pkmn data to remap the species
		pkmn1_copy.box.species = cast(ushort) rom2_candidate_spec1;
		pkmn2_copy.box.species = cast(ushort) rom1_candidate_spec2;
		writefln("  remapped species to: %s (0x%04x) and %s (0x%04x)",
			clean_name(rom2.get_species_name(pkmn1_copy.box.species)), pkmn1_copy.box.species,
			clean_name(rom1.get_species_name(pkmn2_copy.box.species)), pkmn2_copy
				.box.species);

		// return;

		// now, we also need to remap moves
		writefln("REMAP MOVES");

		writef("  species 1 moves: ");
		for (auto i = 0; i < 4; i++) {
			auto move = pkmn1_copy.box.move[i];
			if (!move)
				continue;
			writef("%s (0x%04x) ", clean_name(rom1.get_move_name(move)), move);
		}
		writeln();

		writef("  species 2 moves: ");
		for (auto i = 0; i < 4; i++) {
			auto move = pkmn2_copy.box.move[i];
			if (!move)
				continue;
			writef("%s (0x%04x) ", clean_name(rom2.get_move_name(move)), move);
		}
		writeln();

		long[4] rom1_candidate_moves_spec2 = [-1, -1, -1, -1];
		long[4] rom2_candidate_moves_spec1 = [-1, -1, -1, -1];

		// auto fallback_rom1 = -1;
		// auto fallback_rom2 = -1;
		// enum fallback_move_name = "tackle";

		// for eacho move of pkmn1
		for (auto i = 0; i < 4; i++) {
			auto move_id = pkmn1_copy.box.move[i];
			if (!move_id) {
				// no move
				continue;
			}
			// look up the move name
			auto rom1_move_name = clean_name(rom1.get_move_name(move_id));
			// look up the move name in rom2
			for (auto j = 0; j < rom2.num_moves; j++) {
				auto rom2_move_name = clean_name(rom2.get_move_name(j));
				if (rom2_move_name == rom1_move_name) {
					// found a match
					writefln("  found candidate (0x%04x) in rom 2 for move #%d: %s", j, i, rom2_move_name);
					rom2_candidate_moves_spec1[i] = j;
					break;
				}
				// if (rom2_move_name == fallback_move_name) {
				// 	fallback_rom2 = j;
				// }
			}
		}

		// for eacho move of pkmn2
		for (auto i = 0; i < 4; i++) {
			auto move_id = pkmn2_copy.box.move[i];
			if (!move_id) {
				// no move
				continue;
			}
			// look up the move name
			auto rom2_move_name = clean_name(rom2.get_move_name(move_id));
			// look up the move name in rom1
			for (auto j = 0; j < rom1.num_moves; j++) {
				auto rom1_move_name = clean_name(rom1.get_move_name(j));
				if (rom1_move_name == rom2_move_name) {
					// found a match
					writefln("  found candidate (0x%04x) in rom 1 for move #%d: %s", j, i, rom1_move_name);
					rom1_candidate_moves_spec2[i] = j;
					break;
				}
				// if (rom1_move_name == fallback_move_name) {
				// 	fallback_rom1 = j;
				// }
			}
		}

		// writefln("  %s", rom2_candidate_moves_spec1);
		// writefln("  %s", rom1_candidate_moves_spec2);

		// now we need to hack the pkmn data to remap the moves
		for (auto i = 0; i < 4; i++) {
			if (!pkmn1_copy.box.move[i])
				continue;
			// if the move exists, and there is a candidate, then remap it
			if (rom2_candidate_moves_spec1[i] >= 0) {
				pkmn1_copy.box.move[i] = cast(ushort) rom2_candidate_moves_spec1[i];
				writefln("  remapped move %d to: %s (0x%04x)", i, clean_name(
						rom2.get_move_name(pkmn1_copy.box.move[i])), pkmn1_copy.box.move[i]);
			} else {
				// no match found
				writefln("  could not find matching move #%d (%s) for pkmn 1.", i,
					clean_name(rom1.get_move_name(pkmn1_copy.box.move[i])));
				// // fallback?
				// if (fallback_rom2 >= 0) {
				// 	pkmn1_copy.box.move[i] = cast(ushort) fallback_rom2;
				// 	writefln("  falling back to: %s (0x%04x)",
				// 		clean_name(rom2.get_move_name(pkmn1_copy.box.move[i])), pkmn1_copy.box.move[i]);
				// } else {
				// 	// no fallback, so just set it to 0
				// 	pkmn1_copy.box.move[i] = 0;
				// }
				pkmn1_copy.box.move[i] = 0;
			}
		}

		for (auto i = 0; i < 4; i++) {
			if (!pkmn2_copy.box.move[i])
				continue;
			// if the move exists, and there is a candidate, then remap it
			if (rom1_candidate_moves_spec2[i] >= 0) {
				pkmn2_copy.box.move[i] = cast(ushort) rom1_candidate_moves_spec2[i];
				writefln("  remapped move %d to: %s (0x%04x)", i, clean_name(
						rom1.get_move_name(pkmn2_copy.box.move[i])), pkmn2_copy.box.move[i]);
			} else {
				// no match found
				writefln("  could not find matching move #%d (%s) for pkmn 2.", i,
					clean_name(rom2.get_move_name(pkmn2_copy.box.move[i])));
				// // fallback?
				// if (fallback_rom1 >= 0) {
				// 	pkmn1_copy.box.move[i] = cast(ushort) fallback_rom1;
				// 	writefln("  falling back to: %s (0x%04x)",
				// 		clean_name(rom1.get_move_name(pkmn2_copy.box.move[i])), pkmn2_copy.box.move[i]);
				// } else {
				// 	// no fallback, so just set it to 0
				// 	pkmn2_copy.box.move[i] = 0;
				// }
				pkmn2_copy.box.move[i] = 0;
			}
		}

		// remap held item
		writefln("REMAP ITEM");
		writefln(" ITEMS");
		auto item1_name = clean_name(rom1.get_item_name(pkmn1_copy.box.held_item));
		auto item2_name = clean_name(rom2.get_item_name(pkmn2_copy.box.held_item));

		writefln("  pkmn 1 item: %s (0x%04x)",
			item1_name, pkmn1_copy.box.held_item);
		writefln("  pkmn 2 item: %s (0x%04x)",
			item2_name, pkmn2_copy.box.held_item);

		long rom1_candidate_item2 = -1;
		long rom2_candidate_item1 = -1;

		// now search the other rom to find a matching item name
		if (pkmn2_copy.box.held_item) {
			for (auto i = 0; i < rom1.num_items; i++) {
				auto rom1_scan_item = clean_name(rom1.get_item_name(i));
				if (rom1_scan_item == item2_name) {
					// found a match
					writefln("  found candidate (0x%04x) in rom 1 for item 0x%04x", i, pkmn2_copy
							.box.held_item);
					rom1_candidate_item2 = i;
					break;
				}
			}
		}
		if (pkmn1_copy.box.held_item) {
			for (auto i = 0; i < rom2.num_items; i++) {
				auto rom2_scan_item = clean_name(rom2.get_item_name(i));
				if (rom2_scan_item == item1_name) {
					// found a match
					writefln("  found candidate (0x%04x) in rom 2 for item 0x%04x", i, pkmn1_copy
							.box.held_item);
					rom2_candidate_item1 = i;
					break;
				}
			}
		}

		if (rom1_candidate_item2 >= 0) {
			pkmn2_copy.box.held_item = cast(ushort) rom1_candidate_item2;
			writefln("  remapped pkmn2 item to rom1: %s (0x%04x)", item2_name, pkmn2_copy
					.box.held_item);
		}

		if (rom2_candidate_item1 >= 0) {
			pkmn1_copy.box.held_item = cast(ushort) rom2_candidate_item1;
			writefln("  remapped pkmn1 item to rom2: %s (0x%04x)", item1_name, pkmn1_copy
					.box.held_item);
		}
	}

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

	// // dump both pokemon
	// writeln(dump_prettyprint_pkmn(save1, pkmn1_copy));
	// writeln(dump_prettyprint_pkmn(save2, pkmn2_copy));

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
