const std = @import("std");
const device = @import("device.zig");

pub fn threadDevice(dev: *device.Device) !void {
    while (true) {
        dev.refresh() catch continue;
    }
}

pub fn threadStatusBar(devices: *[]device.Device) !void {
    while (true) {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var final_str: []const u8 = undefined;
        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();
        const length = devices.len;

        for (devices.*, 0..) |d, i| {
            d.mutex.lock();
            defer d.mutex.unlock();

            const section = d.section.* orelse continue;
            const formatted = section.format(allocator);
            defer allocator.free(formatted);
            result.appendSlice(formatted) catch unreachable;

            if (i == length - 1) {
                final_str = result.toOwnedSlice() catch |err| {
                    std.log.err("Error creating final string {}\n", .{err});
                    return error.FinalStringCreationFailed;
                };
            } else {
                result.append('|') catch unreachable;
            }
        }

        callXsetroot(final_str) catch |err| {
            std.log.err("Error calling system xsetroot {}\n", .{err});
        };

        std.time.sleep(100 * std.time.ns_per_ms);
    }
}

pub fn callXsetroot(str: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var child = std.process.Child.init(&.{ "xsetroot", "-name", str }, allocator);

    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Inherit;

    try child.spawn();
    const term = try child.wait();

    switch (term) {
        .Stopped, .Signal, .Unknown => |err| std.log.err("Command failed: {}\n", .{err}),
        .Exited => return,
    }
}

pub fn callSimpleXsetroot(str: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "xsetroot", "-name", str },
    });
}
