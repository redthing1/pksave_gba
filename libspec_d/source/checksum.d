/**
 * @file checksum.h
 * @brief Containes functions for calculation of checksums.
 */

extern (C):

ushort nds_crc16 (const(ubyte)*, size_t);
ushort gba_block_checksum (const(ubyte)*, size_t);
ubyte gb_rby_checksum (const(ubyte)*, size_t);
ushort gb_gsc_checksum (const(ubyte)*, size_t);
ushort pkm_checksum (const(ubyte)*, size_t);
ushort pk3_checksum (const(ubyte)*, size_t);

//__CHECKSUM_H__
