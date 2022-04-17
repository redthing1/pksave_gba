module util;

import std.utf;
import std.string;
import std.array;
import libspec;

wchar[] decode_gba_text(ubyte[] gba_text) {
    auto text_len = gba_text.length;
    ushort[] decoded_buf;
    decoded_buf.length = text_len; // allocate space in buffer
    gba_text_to_ucs2(cast(ushort*) decoded_buf, cast(ubyte*) gba_text, text_len);

    return cast(wchar[]) decoded_buf;
}

string gba_time_to_string(gba_time_t time) {
    return format("%02d:%02d:%02d (%d)", time.hours, time.minutes, time.seconds, time.frames);
}

string format_hex(ubyte[] data) {
    auto sb = appender!string;
    foreach (ch; data) {
        sb ~= format(" %02X", ch);
    }
    return sb[];
}

template hex_array(string byte_dump) {
    import std.string : format;
    import std.array : join;

    string pack_byte_dump_impl() {
        string[] pieces = byte_dump.split(" ");
        string[] byte_strs;

        foreach (piece; pieces) {
            byte_strs ~= format("0x%s", piece);
        }

        return byte_strs.join(", ");
    }

    const char[] hex_array = format("[ %s ]", pack_byte_dump_impl());
}

// KMP algorithm: https://forum.dlang.org/post/ezejemudlhsmqbeavhcl@forum.dlang.org
import std.range: isInputRange, ElementType;
import std.array: array, uninitializedArray, popFront, empty, front;
import std.traits: Unqual, isNarrowString;
    
/**
Range that yields all starting positions of copies of the pattern in
the first Range, using Knuth-Morris-Pratt algorithm. The arguments can
be any ranges, it returns all matches and it scans the first range lazily.
Whenever it yields, it will have read the first range exactly up to
and including the match that caused the yield.
*/
struct KMP(R1, R2) if (isInputRange!R1 && isInputRange!R2) {
    // Adapted from lazy KMP Python code by David Eppstein
    // http://c...content-available-to-author-only...e.com/recipes/117214-knuth-morris-pratt-string-matching/
    private R1 items;
    private const Unqual!(ElementType!R2)[] pattern;
    private const size_t[] shifts;
    private size_t startPos;
    private int matchLen;
    private bool is_empty = true;
    
    this(R1 items_, R2 pattern_) /*pure*/ {
        this.items = items_;
        this.pattern = pattern_.array();
    
        if (this.pattern.length == 0)
            throw new Exception("KMP: pattern can't be empty.");
    
        // build table of shift amounts
        auto table = uninitializedArray!(size_t[])(pattern.length + 1);
        table[] = 1;
        size_t shift = 1;
        foreach (pos; 0 .. pattern.length) {
            while (shift <= pos && pattern[pos] != pattern[pos - shift])
                shift += table[pos - shift];
            table[pos + 1] = shift;
        }
    
        this.shifts = table;
        popFront(); // search first hit
    }
    
    @property bool empty() const pure nothrow {
        return this.is_empty;
    }
    
    @property size_t front() const pure /*nothrow*/ {
        return startPos;
    }
    
    void popFront() /*pure nothrow*/ {
        this.is_empty = true;
        while (!items.empty) {
            auto it = items.front;
            items.popFront();
            while (matchLen == pattern.length ||
                    matchLen >= 0 &&
                    pattern[matchLen] != it) {
                startPos += shifts[matchLen];
                matchLen -= shifts[matchLen];
            }
            matchLen++;
            if (matchLen == pattern.length) {
                this.is_empty = false;
                break;
            }
    
        }
    }
}

KMP!(R1, R2) kmp(R1, R2)(R1 r1, R2 r2) if (isInputRange!R1 && isInputRange!R2) {
    return KMP!(R1, R2)(r1, r2);
}
