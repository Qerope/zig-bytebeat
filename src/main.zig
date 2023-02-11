const std = @import("std");

pub fn main() !void {
    const out = std.io.getStdOut().writer();
    var t: u32 = 0;
    while (t < 8000 * 30) : (t += 1) {
        const s: u8 = @truncate(u8, t *% ((t >> 5) | (t >> 8)));
        try out.writeByte(s);
    }
}
