const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

const sys = @import("syslinfo");
const comps = @import("components.zig");
var mutex = std.Thread.Mutex{};
var finalStr: []const u8 = "";

fn threadComponent(component: *comps.Executor) !void {
    while (true) {
        mutex.lock();
        try component.convert();
        mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * component.time.*);
    }
}

fn threadBar(components: []comps.Executor, alloc: std.heap.ArenaAllocator) void {
    while (true) {
        _ = alloc;
        mutex.lock();
        defer mutex.unlock();
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        const allocator = arena.allocator();
        for (components) |comp| {
            finalStr = std.fmt.allocPrint(allocator, "{s}{s}", .{ finalStr, comp.result.* }) catch "error";
        }
        //         var result = std.ArrayList(u8).init(arena.allocator());
        //         defer result.deinit();
        //         for (components) |comp| {
        //             result.appendSlice(comp.result.*) catch unreachable;
        //             result.append('|') catch unreachable;
        //         }
        //         _ = result.pop();
        //         const finalStr = result.toOwnedSlice() catch "error";

        callXsetroot(finalStr) catch return;

        std.time.sleep(100 * std.time.ns_per_ms);
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
    errdefer arena.deinit();

    const alloc = arena.allocator();

    var cpuComp = comps.Cpu{ .allocator = alloc };
    var tempComp = comps.Temperature{ .allocator = alloc };
    var memComp = comps.Memory{ .allocator = alloc };
    var diskComp = comps.Disk{ .allocator = alloc };
    var volComp = comps.Volume{ .allocator = alloc };
    var dateComp = comps.Date{ .allocator = alloc };

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
