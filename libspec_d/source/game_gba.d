module game_gba;

import libspec_types;

/**
 * The GBA games, Generation 3 games. These games include Ruby, Sapphire, Emerald, Fire Red and Leaf Green.
 *
 * @file game_gba.h
 * @brief Contains the structures and functions for editing GBA pokemon save games.
 */

extern (C):

/**
 * @brief Enum containing the different gba game types.
 */
enum gba_savetype_t
{
    /** An unknown GBA game, no functions will work on this save type. */
    GBA_TYPE_UNKNOWN = 0,
    /** Pokemon Ruby and Pokemon Sapphire */
    GBA_TYPE_RS = 1,
    /** Pokemon Emerald */
    GBA_TYPE_E = 2,
    /** Pokemon Fire Red and Pokemon Leaf Green */
    GBA_TYPE_FRLG = 3
}

enum gba_checksum
{
    GBA_SAVE_SECTION = 0xE000,
    GBA_SAVE_BLOCK_COUNT = 14,
    GBA_BLOCK_LENGTH = 0x1000,
    GBA_BLOCK_DATA_LENGTH = 0xFF4,
    GBA_BLOCK_FOOTER_LENGTH = 0xC,
    GBA_BLOCK_FOOTER_MARK = 0x08012025,
    GBA_CODEPAGE_SIZE = 0x100
}

enum
{
    /** The size in bytes of the GBA save we expect. */
    GBA_SAVE_SIZE = 0x20000,
    /** The unpacked size of a GBA save slot. Represents all the actual data content (as opposed to checksum/control values) of our saves */
    GBA_UNPACKED_SIZE = gba_checksum.GBA_BLOCK_DATA_LENGTH * gba_checksum.GBA_SAVE_BLOCK_COUNT
}

/**
 * @brief A structure used for handling gba save types.
 */
struct gba_save_t
{
    /** @brief The unpacked data for this save. Will always be GBA_UNPACKED_SIZE in length. */
    ubyte* data;
    /** @brief The savetype of the save. */
    gba_savetype_t type;
    /** @brief Internal data used by the library. */

    void* internal;
}

/* Generation 3 Pokemon Data Structure */

/**
 * @brief Defines constants related to the GBA pokemon structure.
 */
enum
{
    /** @brief The size of an individual block in the pokemon structure. */
    PK3_BLOCK_SIZE = 0xC,
    /** @brief The size of the pk3_box_t structure, the box storage structure. */
    PK3_BOX_SIZE = 0x50,
    /** @brief The size of the pk3_t structure, the party storage structure. */
    PK3_PARTY_SIZE = 0x64,
    /** @brief The length of a pokemons nickname. */
    PK3_NICKNAME_LENGTH = 10,
    /** @brief The length of a pokemon's original trainers name. */
    PK3_OT_NAME_LENGTH = 7
}

/**
 * @brief Defines constants related to GBA pokemon storage.
 */
enum
{
    /** The number of boxes in the PC. */
    GBA_BOX_COUNT = 14,
    /** The number of pokemon in a box. */
    GBA_POKEMON_IN_BOX = 30,
    /** The length of a pc box's name. */
    GBA_BOX_NAME_LENGTH = 9
}

enum
{
    GBA_RS_ITEM_COUNT = 216,
    GBA_E_ITEM_COUNT = 236,
    GBA_FRLG_ITEM_COUNT = 216
}

/**
 * @brief Defines the gba item pockets.
 */
enum gba_item_pocket_t
{
    GBA_ITEM_POCKET_PC = 0,
    GBA_ITEM_POCKET_ITEM = 1,
    GBA_ITEM_POCKET_KEYITEM = 2,
    GBA_ITEM_POCKET_BALL = 3,
    GBA_ITEM_POCKET_HMTM = 4,
    GBA_ITEM_POCKET_BERRY = 5
}

// packed structs

/**
 * @brief The pokemon's markings that you see in the party or box. Used for searching.
 */
struct pk3_marking_t
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        ubyte, "circle", 1,
        ubyte, "square", 1,
        ubyte, "triangle", 1,
        ubyte, "heart", 1,
        ubyte, "unused", 4));

    //0x8

    //unused
}

/**
 * @brief The pokemon's effort values.
 */
struct pk3_effort_t
{
    ubyte hp;
    ubyte atk;
    ubyte def;
    ubyte spd;
    ubyte satk;
    ubyte sdef;
}

/**
 * @brief The pokemon's contest stats.
 */
struct pk3_contest_t
{
    ubyte cool;
    ubyte beauty;
    ubyte cute;
    ubyte smart;
    ubyte tough;
    ubyte sheen;
}

/**
 * @brief The pokemon's pokerus infection/strain.
 */
struct pk3_pokerus_t
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        ubyte, "days", 4,
        ubyte, "strain", 4));
}

/**
 * @brief The ppup of each move of the pokemon.
 */
struct pk3_pp_up_t
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        ubyte, "move_0", 2,
        ubyte, "move_1", 2,
        ubyte, "move_2", 2,
        ubyte, "move_3", 2));

    //4
    //6
    //8
}

/**
 * @brief The pokemon's individual values. It's unchangable genes.
 */
struct pk3_genes_t
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        ubyte, "hp", 5,
        ubyte, "atk", 5,
        ubyte, "def", 5,
        ubyte, "spd", 5,
        ubyte, "satk", 5,
        ubyte, "sdef", 5,
        ubyte, "unknown", 2));
}

//pulled from pkm, may not be accurate
/**
 * @brief The pokemon's ribbon data.
 */
struct pk3_ribbon_t
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        ubyte, "cool_normal", 1,
        ubyte, "cool_super", 1,
        ubyte, "cool_hyper", 1,
        ubyte, "cool_master", 1,
        ubyte, "beauty_normal", 1,
        ubyte, "beauty_super", 1,
        ubyte, "beauty_hyper", 1,
        ubyte, "beauty_master", 1,
        ubyte, "cute_normal", 1,
        ubyte, "cute_super", 1,
        ubyte, "cute_hyper", 1,
        ubyte, "cute_master", 1,
        ubyte, "smart_normal", 1,
        ubyte, "smart_super", 1,
        ubyte, "smart_hyper", 1,
        ubyte, "smart_master", 1,
        ubyte, "tough_normal", 1,
        ubyte, "tough_super", 1,
        ubyte, "tough_hyper", 1,
        ubyte, "tough_master", 1,
        ubyte, "champion", 1,
        ubyte, "winning", 1,
        ubyte, "victory", 1,
        ubyte, "artist", 1,
        ubyte, "effort", 1,
        ubyte, "marine", 1,
        ubyte, "land", 1,
        ubyte, "sky", 1,
        ubyte, "country", 1,
        ubyte, "national", 1,
        ubyte, "earth", 1,
        ubyte, "world", 1));

    //0x2
    //byte 1

    //byte 2

    //byte 3

    //byte 4
}

/**
 * @brief A GBA pokemon's box data. 80 bytes in size.
 */
struct pk3_box_t
{
    //80 bytes for box data
    /** @brief Header */
    struct
    {
        import std.bitmanip : bitfields;
        //32 bytes
        /** Personality Value */
        uint pid; //4
        union
        {
            /** Original Trainer Full ID */
            uint ot_fid; //full id
            struct
            {
                /** Original Trainer ID */
                ushort ot_id; //6
                /** Original Trainer Secret ID */
                ushort ot_sid; //8
            }
        }

        /** Pokemon's Nickname */
        ubyte[PK3_NICKNAME_LENGTH] nickname; //18
        /** Original Language */
        ushort language; //20
        /** Original Trainer's Name */
        ubyte[PK3_OT_NAME_LENGTH] ot_name; //27
        /** Pokemon's Markings */
        pk3_marking_t markings; //28
        /** Checksum of all 4 blocks */
        ushort checksum;
        mixin(bitfields!(ushort, "unknown0", 16)); //30
        //32
    }

    /* data */
    union
    {
        //48 bytes
        /** Raw Block Access */
        ubyte[PK3_BLOCK_SIZE][4] block;

        struct
        {
            /** @brief Block A */
            struct
            {
                import std.bitmanip : bitfields;

                /** Pokemon Species */
                ushort species;
                /** Held Item ID */
                ushort held_item;
                /** Experience Points */
                uint exp;
                /** Pokemon Move PPUPs */
                pk3_pp_up_t pp_up;
                /** Friendship Value / Steps to Hatch */
                ubyte friendship;
                mixin(bitfields!(ushort, "unknown1", 16));
            }

            /** @brief Block B */
            struct
            {
                /** Move ID (4) */
                ushort[4] move;
                /** Move PP Remaining (4) */
                ubyte[4] move_pp;
            }

            /** @brief Block C */
            struct
            {
                /** Effort Values */
                pk3_effort_t ev;
                /** Contest Stats */
                pk3_contest_t contest;
            }

            /** @brief Block D */
            struct
            {
                /** Poke'R US Virus */
                pk3_pokerus_t pokerus;
                /** Location Met */
                ubyte met_loc;

                struct
                {
                    import std.bitmanip : bitfields;

                    mixin(bitfields!(
                        ubyte, "level_met", 7,
                        ubyte, "game", 4,
                        ubyte, "pokeball", 4,
                        ubyte, "is_ot_female", 1));

                    /** Level Met At */

                    /** Original Game ID */

                    /** Pokeball Caught In */

                    /** Original Trainer's Gender */
                }

                union
                {
                    /** Pokemon's Individual Values */
                    pk3_genes_t iv;

                    struct
                    {
                        import std.bitmanip : bitfields;

                        mixin(bitfields!(
                            uint, "unknown2", 30,
                            ubyte, "is_egg", 1,
                            ubyte, "ability", 1));

                        /** Is this pokemon an Egg? */

                        /** Which of the two possible abilities does this pokemon have? */
                    }
                }

                /** Pokemon's Ribbons */
                pk3_ribbon_t ribbon;
            }
        }
    }
}

struct pk3_status_t
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        ubyte, "status_sleep", 3,
        ubyte, "status_poison", 1,
        ubyte, "status_burn", 1,
        ubyte, "status_freeze", 1,
        ubyte, "status_paralysis", 1,
        ubyte, "status_toxic", 1));

    /** @brief Turns of sleep status remaining */
}

struct pk3_stats_t
{
    ushort hp;
    ushort max_hp;
    ushort atk;
    ushort def;
    ushort spd;
    ushort satk;
    ushort sdef;
}

struct pk3_party_t
{
    import std.bitmanip : bitfields;

    pk3_status_t status;

    ubyte padding0;
    ubyte padding1;
    ubyte padding2;

    //padding?
    ubyte level;
    ubyte pokerus_time;
    pk3_stats_t stats;
}

/**
 * @brief A GBA pokemon's box and party data. 100 bytes in size.
 */
struct pk3_t
{
    pk3_box_t box;
    pk3_party_t party;
}

/**
 * @brief GBA Party Structure.
 */
struct gba_party_t
{
    /** @brief The number of pokemon currently in the party. */
    uint size;
    /** @brief The individual pokemon in the party. */
    pk3_t[POKEMON_IN_PARTY] pokemon;
}

/**
 * @brief GBA PC Box Structure.
 */
struct gba_pc_box_t
{
    /** @brief The individual pokemon in the box. Indexed visually from Left to Right and Top to Bottom. */
    pk3_box_t[GBA_POKEMON_IN_BOX] pokemon;
}

/**
 * @brief GBA PC Pokemon Storage Structure.
 */
struct gba_pc_t
{
    /**
    	 * This defines what box pokemon will go into when captured with a full party as well as the box you start on when accessing the PC.
    	 * @brief The index of the currently active box, starting at 0.
    	 */
    uint current_box;
    /** @brief The individual boxes in the PC. */
    gba_pc_box_t[GBA_BOX_COUNT] box;
    /** @brief The names of each box in the PC. */
    ubyte[GBA_BOX_NAME_LENGTH][GBA_BOX_COUNT] name;
    /** @brief The wallpaper index for each box of the PC. */
    ubyte[GBA_BOX_COUNT] wallpaper;
}

/**
 * @brief GBA Item Slot Structure.
 */
struct gba_item_slot_t
{
    /** The item index in this slot. */
    ushort index;
    /** The total number of that item. */
    ushort amount;
}

/**
 * @brief GBA Time Played Structure
 */
struct gba_time_t
{
    ushort hours;
    ubyte minutes;
    ubyte seconds;
    ubyte frames; //about 1/60 of a second
}

/**
 * @brief GBA Trainer Data Structure
 */
struct gba_trainer_t
{
    ubyte[7] name; // (0x0)
    ubyte padding0; // (0x7)
    //padding
    ubyte gender; // (0x8)
    ubyte padding1; // (0x9)
    
    // trainer (0xA)
    union
    {
        uint fid;

        struct
        {
            ushort id;
            ushort sid;
        }
    }

    gba_time_t time_played; // time (0xE)
}

union gba_security_key_t
{
    uint key;

    struct
    {
        ushort lower;
        ushort upper;
    }
}

enum gba_game_detect
{
    GBA_GAME_CODE_OFFSET = 0xAC,
    GBA_RSE_SECURITY_KEY_OFFSET = 0xAC,
    GBA_RSE_SECURITY_KEY2_OFFSET = 0x1F4,
    GBA_FRLG_SECURITY_KEY_OFFSET = 0xAF8,
    GBA_FRLG_SECURITY_KEY2_OFFSET = 0xF20
}

void gba_text_to_ucs2 (ushort* dst, ubyte* src, size_t size);
void ucs2_to_gba_text (ubyte* dst, ushort* src, size_t size);

gba_security_key_t gba_get_security_key(ubyte *ptr);

gba_save_t* gba_read_main_save (const(ubyte)*);
gba_save_t* gba_read_backup_save (const(ubyte)*);
void gba_write_main_save (ubyte*, const(gba_save_t)*);
void gba_write_backup_save (ubyte*, const(gba_save_t)*);
void gba_save_game (ubyte*, gba_save_t*);

void gba_free_save (gba_save_t*);
ubyte* gba_create_data ();

void pk3_decrypt (pk3_box_t*);
void pk3_encrypt (pk3_box_t*);

uint gba_get_money (gba_save_t*);
void gba_set_money (gba_save_t*, uint);

gba_item_slot_t* gba_get_item (gba_save_t*, size_t);
gba_item_slot_t* gba_get_pocket_item (gba_save_t*, gba_item_pocket_t, size_t);
size_t gba_get_pocket_offset (gba_save_t*, gba_item_pocket_t);
size_t gba_get_pocket_size (gba_save_t*, gba_item_pocket_t);

gba_trainer_t* gba_get_trainer (gba_save_t*);
gba_party_t* gba_get_party (gba_save_t*);
gba_pc_t* gba_get_pc (gba_save_t*);

ubyte gba_pokedex_get_national (gba_save_t*);
void gba_pokedex_set_national (gba_save_t*, ubyte);
ubyte gba_pokedex_get_owned (gba_save_t*, size_t);
void gba_pokedex_set_owned (gba_save_t*, size_t, ubyte);
ubyte gba_pokedex_get_seen (gba_save_t*, size_t);
void gba_pokedex_set_seen (gba_save_t*, size_t, ubyte);

//TODO rival name, badges, day care pokemon (then GBA is done :D)

//__GBA_H__
