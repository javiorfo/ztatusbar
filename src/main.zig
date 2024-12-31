const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

const sys = @import("syslinfo");
const comps = @import("components.zig");

const Component = struct {
    head: []const u8,
    fun: *const fn ([]const u8) []const u8,
    result: []const u8 = "",
    time: u32,
};

fn threadComponent(component: *comps.Executor) !void {
    var mutex = std.Thread.Mutex{};
    while (true) {
        mutex.lock();
        defer mutex.unlock();
        try component.convert();
        std.time.sleep(std.time.ns_per_ms * component.time.*);
    }
}

fn threadBar(components: []comps.Executor) void {
    var mutex = std.Thread.Mutex{};
    while (true) {
        mutex.lock();
        defer mutex.unlock();

        //         var finalStr: []const u8 = "";
        //         const allocator = std.heap.page_allocator;
        //
        //         for (components) |comp| {
        //             finalStr = std.fmt.allocPrint(allocator, "{s}{s}", .{ finalStr, comp.result.* }) catch "error";
        //         }
        var result = std.ArrayList(u8).init(std.heap.page_allocator);
        defer result.deinit();

        for (components) |comp| {
            result.appendSlice(comp.result.*) catch unreachable;
        }

        const finalStr = result.toOwnedSlice() catch "error";

        callXsetroot(finalStr) catch return;
        for (components) |comp| {
            comp.deinit();
        }
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

fn disk(arg: []const u8) []const u8 {
    const m = sys.disk.usage("/") catch {
        return "";
    };
    const p = m.percentageUsed() catch 0;
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {d}% | ", .{ arg, p }) catch "error";
}

fn ram(arg: []const u8) []const u8 {
    const m = sys.memory.usage() catch {
        return "";
    };
    const p = m.percentageUsed() catch 0;
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {d:.0}% | ", .{ arg, p }) catch "error";
}

fn cpu(arg: []const u8) []const u8 {
    const p = sys.cpu.percentageUsed() catch 0;
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {d:.0}% | ", .{ arg, p }) catch "error";
}

fn temp(arg: []const u8) []const u8 {
    const p = sys.thermal.getTemperatureFromZone(sys.thermal.ZONE.two) catch 0;
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {d:.0}% | ", .{ arg, p }) catch "error";
}

fn volume(arg: []const u8) []const u8 {
    const p = sys.volume.state(.{}) catch {
        return "error";
    };
    if (!p.muted) {
        return std.fmt.allocPrint(std.heap.page_allocator, "  {s} {d}% | ", .{ arg, p.volume }) catch "error";
    }
    return std.fmt.allocPrint(std.heap.page_allocator, "󰖁  {s} MUTED | ", .{arg}) catch "error";
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
    var cpuComp = comps.Cpu{};
    var memComp = comps.Memory{};
    var volComp = comps.Volume{};
    var components = [_]comps.Executor{
        cpuComp.toExecutor(), memComp.toExecutor(), volComp.toExecutor(),
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
