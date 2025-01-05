const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

const sys = @import("syslinfo");
const comps = @import("components.zig");

fn threadComponent(component: *comps.Executor) !void {
    while (true) {
        try component.convert();
        component.deinit();
    }
}

fn threadBar(components: []comps.Executor) !void {
    while (true) {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        var final_str: []const u8 = "";
        var result = std.ArrayList(u8).init(arena.allocator());
        defer result.deinit();
        const length = components.len;
        for (components, 0..) |comp, i| {
            comp.mutex.lock();
            defer comp.mutex.unlock();
            result.appendSlice(comp.result.*) catch unreachable;

            if (i == length - 1) {
                final_str = result.toOwnedSlice() catch |err| {
                    std.log.err("Error creating final string {}\n", .{err});
                    return error.FinalStringCreationFailed;
                };
            } else {
                result.append('|') catch unreachable;
            }
        }
        //         if (result.items.len != 0) _ = result.pop();
        //         final_str = result.toOwnedSlice() catch |err| {
        //             std.log.err("Error creating final string {}\n", .{err});
        //             return error.FinalStringCreationFailed;
        //         };

        //         for (components) |comp| comp.mutex.unlock();

        callXsetroot(final_str) catch |err| {
            std.log.err("Error calling system xsetroot {}\n", .{err});
        };

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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
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

    const tbar = try std.Thread.spawn(.{}, threadBar, .{&components});
    for (threads) |thread| {
        thread.join();
    }
    tbar.join();
}
