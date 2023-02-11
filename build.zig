const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("bytebeat", "src/main.zig");
    exe.setBuildMode(mode);
    exe.install();
}
