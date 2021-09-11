module stat;

/**
 * @file stat.h
 * @brief Contains functions for calculating the stats of pokemon.
 */

extern (C):

/**
 * @brief List of natures by index.
 */
enum stat_nature_t
{
    NATURE_HARDY = 0,
    NATURE_LONELY = 1,
    NATURE_BRAVE = 2,
    NATURE_ADAMANT = 3,
    NATURE_NAUGHTY = 4,
    NATURE_BOLD = 5,
    NATURE_DOCILE = 6,
    NATURE_RELAXED = 7,
    NATURE_IMPISH = 8,
    NATURE_LAX = 9,
    NATURE_TIMID = 10,
    NATURE_HASTY = 11,
    NATURE_SERIOUS = 12,
    NATURE_JOLLY = 13,
    NATURE_NAIVE = 14,
    NATURE_MODEST = 15,
    NATURE_MILD = 16,
    NATURE_QUIET = 17,
    NATURE_BASHFUL = 18,
    NATURE_RASH = 19,
    NATURE_CALM = 20,
    NATURE_GENTLE = 21,
    NATURE_SASSY = 22,
    NATURE_CAREFUL = 23,
    NATURE_QUIRKY = 24
}

/**
 * List of stats by index.
 */
enum stat_stat_t
{
    STAT_HP = 0,
    STAT_ATTAK = 1,
    STAT_DEFENSE = 2,
    STAT_SPEED = 3,
    STAT_SP_ATTACK = 4,
    STAT_SP_DEFENSE = 5
}

/**
 * @brief Enum to tell the stat functions if a nature is beneficial or otherwise.
 */
enum stat_bonus_t
{
    /** A neutral bonus for the given stat. */
    STAT_BONUS_NONE = 0,
    /** A beneficial bonus for the given stat. */
    STAT_BONUS_POSITIVE = 1,
    /** A harmful bonus for the given stat. */
    STAT_BONUS_NEGATIVE = 2
}

/**
 * @brief Erratic Experience Table, indexed 0 to 99 for levels 1 to 100.
 */
extern __gshared const(uint)[100] STAT_TOTAL_EXP_ERRATIC;

/**
 * @brief Fast Experience Table, indexed 0 to 99 for levels 1 to 100.
 */
extern __gshared const(uint)[100] STAT_TOTAL_EXP_FAST;

/**
 * @brief Medium Fast Experience Table, indexed 0 to 99 for levels 1 to 100.
 */
extern __gshared const(uint)[100] STAT_TOTAL_EXP_MEDIUM_FAST;

/**
 * @brief Medium Slow Experience Table, indexed 0 to 99 for levels 1 to 100.
 */
extern __gshared const(uint)[100] STAT_TOTAL_EXP_MEDIUM_SLOW;

/**
 * @brief Slow Experience Table, indexed 0 to 99 for levels 1 to 100.
 */
extern __gshared const(uint)[100] STAT_TOTAL_EXP_SLOW;

/**
 * @brief Fluctuating Experience Table, indexed 0 to 99 for levels 1 to 100.
 */
extern __gshared const(uint)[100] STAT_TOTAL_EXP_FLUCTUATING;

enum stat_growth_rate_t
{
    STAT_GROWTH_RATE_ERRATIC = 0,
    STAT_GROWTH_RATE_FAST = 1,
    STAT_GROWTH_RATE_MEDIUM_FAST = 2,
    STAT_GROWTH_RATE_MEDIUM_SLOW = 3,
    STAT_GROWTH_RATE_SLOW = 4,
    STAT_GROWTH_RATE_FLUCTUATING = 5
}

stat_bonus_t stat_get_bonus (stat_nature_t, stat_stat_t);
stat_nature_t stat_get_nature (uint pid);
ubyte stat_get_level (stat_growth_rate_t, uint exp);

ushort gb_calc_stat (ubyte, ubyte, ubyte, ushort);
ushort gb_calc_hp_stat (ubyte, ubyte, ubyte, ushort);

ushort gba_calc_stat (ubyte, ubyte, ubyte, ubyte, stat_bonus_t);
ushort gba_calc_hp_stat (ubyte, ubyte, ubyte, ubyte);

ushort nds_calc_stat (ubyte level, ubyte base_stat, ubyte iv, ubyte ev, stat_bonus_t);
ushort nds_calc_hp_stat (ubyte, ubyte, ubyte, ubyte);

ushort dsi_calc_stat (ubyte level, ubyte base_stat, ubyte iv, ubyte ev, stat_bonus_t);
ushort dsi_calc_hp_stat (ubyte, ubyte, ubyte, ubyte);

/* STAT_H_ */
