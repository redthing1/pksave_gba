module util;

import std.utf;
import libspec;

wchar[] decode_gba_text(ubyte[] gba_text) {
    auto text_len = gba_text.length;
    ushort[] decoded_buf;
    decoded_buf.length = text_len; // allocate space in buffer
    gba_text_to_ucs2(cast(ushort*) decoded_buf, cast(ubyte*) gba_text, text_len);

    return cast(wchar[]) decoded_buf;
}