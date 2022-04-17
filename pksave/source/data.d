module data;

import std.string;
import std.conv;
import std.sumtype;

import util;

enum Gender {
    Unknown,
    Male,
    Female
}

enum PkmnNature {
    Hardy = 0,
    Lonely = 1,
    Brave = 2,
    Adamant = 3,
    Naughty = 4,
    Bold = 5,
    Docile = 6,
    Relaxed = 7,
    Impish = 8,
    Lax = 9,
    Timid = 10,
    Hasty = 11,
    Serious = 12,
    Jolly = 13,
    Naive = 14,
    Modest = 15,
    Mild = 16,
    Quiet = 17,
    Bashful = 18,
    Rash = 19,
    Calm = 20,
    Gentle = 21,
    Sassy = 22,
    Careful = 23,
    Quirky = 24,
}

enum PkmnTypeGen3 {
    Normal = 0,
    Fighting = 1,
    Flying = 2,
    Poison = 3,
    Ground = 4,
    Rock = 5,
    Bug = 6,
    Ghost = 7,
    Steel = 8,
    Fairy = 9, // SGS only
    Fire = 10,
    Water = 11,
    Grass = 12,
    Electric = 13,
    Psychic = 14,
    Ice = 15,
    Dragon = 16,
    Dark = 17,
}

enum PkmnTypeGeneral {
    Normal = 0,
    Fighting = 1,
    Flying = 2,
    Poison = 3,
    Ground = 4,
    Rock = 5,
    Bug = 6,
    Ghost = 7,
    Steel = 8,
    Fire = 9,
    Water = 10,
    Grass = 11,
    Electric = 12,
    Psychic = 13,
    Ice = 14,
    Dragon = 15,
    Dark = 16,
    Fairy = 17,
    Question = 18,
}

struct Personality {
    ubyte raw_gender;
    Gender gender;

    ubyte raw_extra_ability;

    ubyte raw_nature;
    PkmnNature nature;

    ushort raw_shiny;
    bool shiny;

    string toString() const {
        import std.string : format;

        return format("gender: %s, nature: %s, shiny: %s", gender, nature, shiny);
    }
}

align(1) {
    struct PkmnROMSpecies {
    align(1):
        struct {
            ubyte hp;
            ubyte atk;
            ubyte def;
            ubyte spd;
            ubyte satk;
            ubyte sdef;
        }

        struct {
            ubyte type1;
            ubyte type2;
        }

        struct {
            ubyte catch_rate;
            ubyte exp_yield;
            ushort effort_yield;
        }

        struct {
            ushort item1;
            ushort item2;
            ubyte gender;
        }

        ubyte egg_cycles;
        ubyte friendship;
        ubyte lvl_up_type;
        struct {
            ubyte egg_group_1;
            ubyte egg_group_2;
        }

        struct {
            ubyte ability1;
            ubyte ability2;
        }

        ubyte safari_zone_rate;
        ubyte color_flip;
        ushort unknown0;

        string toString() const {
            import std.string : format;

            string type1_s, type2_s;
            try {
                type1_s = format("%s", type1.to!PkmnTypeGen3);
                type2_s = format("%s", type2.to!PkmnTypeGen3);
            } catch (ConvException e) {
                type1_s = format("%s", type1);
                type2_s = format("%s", type2);
            }

            return format("hp: %s, atk: %s, def: %s, spd: %s, satk: %s, sdef: %s, type1: %s, type2: %s",
                    hp, atk, def, spd, satk, sdef, type1_s, type2_s)~format(", gender: %s",
                    gender);
        }
    }

    struct PkmnROMItem {
    align(1):
        ubyte[14] name;
        ushort index;
        ushort price;
        ubyte hold_effect;
        ubyte parameter0;
        uint description_ptr;
        ushort mystery0;
        ubyte pocket;
        ubyte type;
        uint field_usage_ptr;
        uint battle_usage;
        uint battle_usage_ptr;
        uint parameter1;

        string toString() const {
            import std.string : format;

            return format("id: %s, name: %s, price: %s", index,
                    decode_gba_text(name.dup).strip(), price);
        }
    }

    struct PkmnROMLevelUpMove16 {
    align(1):
        import std.bitmanip : bitfields;

        union {
            struct {
                // 9 bits for move, 7 bits for level
                mixin(bitfields!(ushort, "move", 9, ushort, "level", 7));
            }
            ushort[1] raw;
        }
    }

    struct PkmnROMLevelUpMove32 {
    align(1):
        union {
            struct {
                ushort move;
                ushort level;
            }
            ushort[2] raw;
        }
    }

    // alias PkmnROMLevelUpMove = SumType!(
    //     PkmnROMLevelUpMove16,
    //     PkmnROMLevelUpMove32
    // );

    struct PkmnROMLearnset16 {
    align(1):
        PkmnROMLevelUpMove16[] moves;
    }

    struct PkmnROMLearnset32 {
    align(1):
        PkmnROMLevelUpMove32[] moves;
    }

    alias PkmnROMLearnset = SumType!(
        PkmnROMLearnset16,
        PkmnROMLearnset32
    );
}
