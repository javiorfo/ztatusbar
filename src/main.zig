const std = @import("std");
const initializer = @import("initializer.zig");

pub fn main() !void {
    std.process.raiseFileDescriptorLimit();
    try initializer.initialize();
}
