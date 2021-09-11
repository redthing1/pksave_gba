module prng;

/**
 * @file prng.h
 * @brief Contains the Psudo-Random Number Generator used by the games.
 */

extern (C):

/**
 * @brief Defines a prng seed value.
 */
alias prng_seed_t = uint;

void prng_prev_seed (prng_seed_t*);
void prng_next_seed (prng_seed_t*);
ushort prng_prev (prng_seed_t*);
ushort prng_next (prng_seed_t*);
ushort prng_current (prng_seed_t*);

//__PRNG_H__
