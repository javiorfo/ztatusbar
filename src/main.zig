const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

const Component = struct {
    head: []const u8,
    fun: *const fn ([]const u8) []const u8,
    result: []const u8 = "",
    time: u32,
};

fn threadComponent(component: *Component) void {
    var mutex = std.Thread.Mutex{};
    while (true) {
        mutex.lock();
        defer mutex.unlock();

        component.result = component.fun(component.head);
        //         if (component.result == null) {
        //             continue;
        //         }
        std.time.sleep(std.time.ns_per_ms * component.time);
    }
}

fn threadBar(components: []Component) void {
    var mutex = std.Thread.Mutex{};
    while (true) {
        mutex.lock();
        defer mutex.unlock();

        var finalStr: []const u8 = "";

        for (components) |comp| {
            finalStr = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ finalStr, comp.result }) catch "error";
        }
        std.debug.print("{s}\n", .{finalStr});

        std.time.sleep(100 * std.time.ns_per_ms);
    }
}

var v2: usize = 0;
fn uno(arg: []const u8) []const u8 {
    v2 += 1;
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {d} | ", .{ arg, v2 }) catch "error";
}

var v: usize = 0;
fn dos(arg: []const u8) []const u8 {
    v += 1;
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {d} | ", .{ arg, v }) catch "error";
}

fn tres(arg: []const u8) []const u8 {
    const DATE_FORMAT = "%A %d/%m/%Y %H:%M:%S";
    var now: c.time_t = c.time(null);
    const local: *c.struct_tm = c.localtime(&now);

    var buffer: [80]u8 = undefined;
    const len = c.strftime(&buffer, 80, DATE_FORMAT, local);
    return std.fmt.allocPrint(std.heap.page_allocator, "{s} {s} ", .{ arg, buffer[0..len] }) catch "error";
}

pub fn main() !void {
    var components = [_]Component{
        //         .{ .head = "Uno", .fun = uno, .time = 500 },
        //         .{ .head = "Dos", .fun = dos, .time = 1000 },
        .{ .head = "", .fun = tres, .time = 1000 },
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
