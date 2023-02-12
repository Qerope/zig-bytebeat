const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    if (args.len < 4) {
        std.debug.print("usage: bytebeat FORMULA RATE SECONDS\n", .{});
        std.process.exit(2);
    }
    const formula = args[1];
    const rate = try std.fmt.parseInt(u32, args[2], 10);
    const seconds = try std.fmt.parseInt(u32, args[3], 10);
    const out = std.io.getStdOut().writer();
    var t: u32 = 0;
    while (t < rate * seconds) : (t += 1) {
        const s: u8 = @truncate(u8, t *% ((t >> 5) | (t >> 8)));
        try out.writeByte(s);
    }
}
