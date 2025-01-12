const std = @import("std");
const initializer = @import("initializer.zig");

pub fn main() !void {
    std.process.raiseFileDescriptorLimit();
    std.log.debug("Initializing ztatusbar...", .{});
    try initializer.initialize();
    std.log.debug("Stopped.", .{});
}
