module dump;

import std.string;
import std.stdio;
import std.array;
import std.format;

import libspec;
import util;
import pokesave;
import pokegame;

string dump_prettyprint_pkmn(T)(PokeSave save, T pkmn) {
    // static if (T !is pk3_t && T !is pk3_box_t) {
    static if (!is(T == pk3_t) && !is(T == pk3_box_t)) {
        import std.traits;
        static assert(0, format(
            "pkmn type can only be pk3_t or pk3_box_t, not %s",
            fullyQualifiedName!T
        ));
    }
    auto sb = appender!(string);

    // get box based on whether this is a party or box pokemon
    pk3_box_t box;
    static if (is(T == pk3_t)) {
        box = pkmn.box;
    } else static if (is(T == pk3_box_t)) {
        box = pkmn;
    }
    // store checksum
    auto box_cksum = box.checksum;
    // decrypt local copy of box
    pk3_decrypt(&box);

    // main info
    sb ~= format("  NAME: %s (raw:%s)\n", decode_gba_text(box.nickname), format_hex(box.nickname));
    sb ~= format("    SPECIES: 0x%04X\n", box.species);
    sb ~= format("    TRAINER: %s\n", decode_gba_text(box.ot_name));
    
    // if this is a party pokemon, we can show level and stats
    static if (is(T == pk3_t)) {
        sb ~= format("    LEVEL: %s\n", pkmn.party.level);
        sb ~= format("    STATS: %s\n", pkmn.party.stats);
    }

    // other misc info
    sb ~= format("    IVS: %s\n", box.iv);
    sb ~= format("    EVS: %s\n", box.ev);
    sb ~= format("    FRIENDSHIP: %.0f%%\n", (box.friendship / 255.0) * 100.0);

    // if rom is loaded, we can show more detailed information
    if (save.rom_loaded) {
        // species info
        auto species_basestats = save.rom.get_species_basestats(box.species);
        auto species_name = decode_gba_text(save.rom.get_species_name(box.species)).strip();
        sb ~= format("    SPECIES: %s (%s)\n", species_name, species_basestats.toString());

        // held item info
        auto held_item_id = box.held_item;
        if (held_item_id) {
            auto held_item_info = *save.rom.get_item_info(held_item_id);
            sb ~= format("    ITEM: %s (0x%04x)\n",
                decode_gba_text(held_item_info.name.dup).strip(), held_item_id);
        }
    }

    // personality info
    auto personality = save.parse_personality(box);
    sb ~= format("    PERSONALITY: (%s)", personality);

    // verify checksum (by recomputing)
    ushort local_checksum = pk3_checksum(cast(const(ubyte*)) box.block,
            pk3_encryption.PK3_DATA_SIZE);
    auto cksum_validity = (box_cksum == local_checksum) ? "VALID" : "INVALID";
    sb ~= format("    CKSUM: 0x%04X (%s) (orig: 0x%04X)", local_checksum,
            cksum_validity, box_cksum);
    
    return sb.array;
}
