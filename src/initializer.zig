const std = @import("std");
const device = @import("device.zig");
const statusbar = @import("statusbar.zig");
const tomlz = @import("tomlz");

const config_file = ".config/ztatusbar/config.toml";

pub fn initialize() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();
    const home = env_map.get("HOME") orelse return error.HomeEnvVarNoAvailable;

    const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, config_file });
    defer allocator.free(path);

    var devices_list = std.ArrayList(device.Device).init(allocator);
    defer devices_list.deinit();
    var toml: ?tomlz.parser.Table = null;

    if (std.fs.openFileAbsolute(path, .{})) |file| {
        defer file.close();
        const file_info = try file.getEndPos();

        const buffer: []u8 = try allocator.alloc(u8, file_info);
        defer allocator.free(buffer);

        const bytes_read = try file.readAll(buffer);
        if (bytes_read != file_info) return error.FileReadError;

        var table = try tomlz.parse(allocator, buffer);
        toml = table;

        if (table.getTable("cpu")) |item| {
            var cpu = device.Cpu{
                .icon = item.getString("icon") orelse " ",
                .name = item.getString("name") orelse "CPU",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1000)),
            };
            try devices_list.append(cpu.toDevice());
        }
        if (table.getTable("temperature")) |item| {
            var temp = device.Temperature{
                .icon = item.getString("icon") orelse "󰏈 ",
                .name = item.getString("name") orelse "TEMP",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1000)),
            };
            try devices_list.append(temp.toDevice());
        }
        if (table.getTable("memory")) |item| {
            var mem = device.Memory{
                .icon = item.getString("icon") orelse " ",
                .name = item.getString("name") orelse "RAM",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1000)),
            };
            try devices_list.append(mem.toDevice());
        }
        if (table.getTable("disk")) |item| {
            var disk = device.Disk{
                .icon = item.getString("icon") orelse "󰋊 ",
                .name = item.getString("name") orelse "DISK",
                .unit = try std.fmt.allocPrintZ(allocator, "{s}", .{item.getString("unit") orelse "/"}),
                .time = @as(u64, @intCast(item.getInteger("time") orelse 2000)),
            };
            try devices_list.append(disk.toDevice());
        }
        if (table.getTable("volume")) |item| {
            var vol = device.Volume{
                .icon = item.getString("icon") orelse " ",
                .icon_muted = item.getString("icon") orelse "󰖁 ",
                .name = item.getString("name") orelse "VOL",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 100)),
            };
            try devices_list.append(vol.toDevice());
        }
        if (table.getTable("date")) |item| {
            var date = device.Date{
                .icon = item.getString("icon") orelse " ",
                .format = try std.fmt.allocPrintZ(allocator, "{s}", .{item.getString("format") orelse "%A %d/%m/%Y %H:%M:%S"}),
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1000)),
            };
            try devices_list.append(date.toDevice());
        }
    } else |_| {
        var cpu = device.Cpu{};
        var temp = device.Temperature{};
        var mem = device.Memory{};
        var disk = device.Disk{};
        var vol = device.Volume{};
        var date = device.Date{};

        try devices_list.append(cpu.toDevice());
        try devices_list.append(temp.toDevice());
        try devices_list.append(mem.toDevice());
        try devices_list.append(disk.toDevice());
        try devices_list.append(vol.toDevice());
        try devices_list.append(date.toDevice());
    }

    try execute(&devices_list, 6);

    if (toml != null) toml.?.deinit(allocator);

    return error.InitializationError;
}

fn execute(devices_list: *std.ArrayList(device.Device), size: usize) !void {
    var devices = try devices_list.toOwnedSlice();

    const threads = try std.heap.page_allocator.alloc(std.Thread, size);
    defer std.heap.page_allocator.free(threads);

    for (devices, 0..) |*dev, i| {
        threads[i] = try std.Thread.spawn(.{}, statusbar.threadDevice, .{dev});
    }
    const tbar = try std.Thread.spawn(.{}, statusbar.threadStatusBar, .{&devices});
    for (threads) |thread| {
        thread.join();
    }
    tbar.join();
}
