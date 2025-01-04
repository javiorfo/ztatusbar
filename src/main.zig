const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

const sys = @import("syslinfo");
const comps = @import("components.zig");

fn threadComponent(component: *comps.Executor) !void {
    while (true) {
        component.mutex.lock();
        defer component.mutex.unlock();
        try component.convert();
        std.time.sleep(std.time.ns_per_ms * component.time.*);
    }
}

fn threadBar(components: []comps.Executor, arena_comp: std.heap.ArenaAllocator) void {
    var mutex = std.Thread.Mutex{};
    while (true) {
        mutex.lock();
        defer mutex.unlock();
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        var final_str: []const u8 = "";
        var result = std.ArrayList(u8).init(arena.allocator());
        defer result.deinit();
        for (components) |comp| {
            result.appendSlice(comp.result.*) catch unreachable;
            result.append('|') catch unreachable;
        }
        if (result.items.len != 0) _ = result.pop();
        final_str = result.toOwnedSlice() catch "error getting string";

        callXsetroot(final_str) catch return;

        std.time.sleep(100 * std.time.ns_per_ms);
        arena_comp.deinit();
    }
}

fn callXsetroot(str: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = [_][]const u8{ "xsetroot", "-name", str };
    var child = std.process.Child.init(&args, allocator);

    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Inherit;

    try child.spawn();
    const term = try child.wait();

    switch (term) {
        .Stopped, .Signal, .Unknown => |err| std.debug.print("Command failed: {}\n", .{err}),
        .Exited => return,
    }
}

fn date(arg: []const u8) []const u8 {
    const DATE_FORMAT = "%A %d/%m/%Y %H:%M:%S";
    var now: c.time_t = c.time(null);
    const local: *c.struct_tm = c.localtime(&now);

    var buffer: [80]u8 = undefined;
    const len = c.strftime(&buffer, 80, DATE_FORMAT, local);
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {s} ", .{ arg, buffer[0..len] }) catch "error";
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var cpuComp = comps.Cpu{ .allocator = arena.allocator() };
    var tempComp = comps.Temperature{ .allocator = arena.allocator() };
    var memComp = comps.Memory{ .allocator = arena.allocator() };
    var diskComp = comps.Disk{ .allocator = arena.allocator() };
    var volComp = comps.Volume{ .allocator = arena.allocator() };
    var dateComp = comps.Date{ .allocator = arena.allocator() };

    var components = [_]comps.Executor{
        cpuComp.toExecutor(),  tempComp.toExecutor(), memComp.toExecutor(),
        diskComp.toExecutor(), volComp.toExecutor(),  dateComp.toExecutor(),
    };

    var threads: [components.len]std.Thread = undefined;

    for (&components, 0..) |*comp, i| {
        threads[i] = try std.Thread.spawn(.{}, threadComponent, .{comp});
    }

    const tbar = try std.Thread.spawn(.{}, threadBar, .{ &components, arena });
    for (threads) |thread| {
        thread.join();
    }
    tbar.join();
}
