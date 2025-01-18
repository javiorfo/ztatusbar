const std = @import("std");
const device = @import("device.zig");
const statusbar = @import("statusbar.zig");
const tomlz = @import("tomlz");
const sys = @import("syslinfo");

const config_file = ".config/ztatusbar/config.toml";

pub var separator: u8 = '|';

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
    var size: usize = 0;

    if (std.fs.openFileAbsolute(path, .{})) |file| {
        std.log.debug("Getting configuration from toml file.", .{});
        defer file.close();
        const file_info = try file.getEndPos();

        const buffer: []u8 = try allocator.alloc(u8, file_info);
        defer allocator.free(buffer);

        const bytes_read = try file.readAll(buffer);
        if (bytes_read != file_info) return error.FileReadError;

        var table = try tomlz.parse(allocator, buffer);
        toml = table;

        if (table.getTable("general")) |item| {
            std.log.debug("'general' from toml file.", .{});
            if (item.getString("separator")) |sep| {
                if (sep.len > 1 or sep.len == 0) return error.SeparatorMustBeSingleChar;
                separator = sep[0];
            }
        }

        if (table.getTable("cpu")) |item| {
            std.log.debug("'cpu' from toml file.", .{});
            var cpu = device.Cpu{
                .icon = item.getString("icon") orelse " ",
                .name = item.getString("name") orelse "CPU",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1_000)),
            };
            try devices_list.append(cpu.toDevice());
            size += 1;
        }
        if (table.getTable("temperature")) |item| {
            std.log.debug("'temperature' from toml file.", .{});
            var temp = device.Temperature{
                .icon = item.getString("icon") orelse "󰏈 ",
                .name = item.getString("name") orelse "TEMP",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1_000)),
                .thermal_zone = sys.thermal.ZONE.getEnum(@as(u4, @intCast(item.getInteger("zone") orelse 0))),
            };
            try devices_list.append(temp.toDevice());
            size += 1;
        }
        if (table.getTable("memory")) |item| {
            std.log.debug("'memory' from toml file.", .{});
            var mem = device.Memory{
                .icon = item.getString("icon") orelse " ",
                .name = item.getString("name") orelse "RAM",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1_000)),
            };
            try devices_list.append(mem.toDevice());
            size += 1;
        }
        if (table.getTable("disk")) |item| {
            std.log.debug("'disk' from toml file.", .{});
            var disk = device.Disk{
                .icon = item.getString("icon") orelse "󰋊 ",
                .name = item.getString("name") orelse "DISK",
                .unit = try std.fmt.allocPrintZ(allocator, "{s}", .{item.getString("unit") orelse "/"}),
                .time = @as(u64, @intCast(item.getInteger("time") orelse 2_000)),
            };
            try devices_list.append(disk.toDevice());
            size += 1;
        }
        if (table.getTable("volume")) |item| {
            std.log.debug("'volume' from toml file.", .{});
            var vol = device.Volume{
                .icon = item.getString("icon") orelse " ",
                .icon_muted = item.getString("icon_muted") orelse "󰖁 ",
                .name = item.getString("name") orelse "VOL",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 100)),
            };
            try devices_list.append(vol.toDevice());
            size += 1;
        }
        if (table.getTable("network")) |item| {
            std.log.debug("'network' from toml file.", .{});
            var net = device.Network{
                .icon = item.getString("icon") orelse "󰀂 ",
                .icon_down = item.getString("icon_down") orelse "󰯡 ",
                .name = item.getString("name") orelse "NET",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 5_000)),
            };
            try devices_list.append(net.toDevice());
            size += 1;
        }
        if (table.getTable("battery")) |item| {
            std.log.debug("'battery' from toml file.", .{});
            var bat = device.Battery{
                .icon_full = item.getString("icon_full") orelse "󰁹",
                .icon_half = item.getString("icon_half") orelse "󰁿",
                .icon_low = item.getString("icon_low") orelse "󰁺",
                .name = item.getString("name") orelse "BAT",
                .path = item.getString("path") orelse return error.PowerSupplyFileMissing,
                .time = @as(u64, @intCast(item.getInteger("time") orelse 10_000)),
            };
            try devices_list.append(bat.toDevice());
            size += 1;
        }
        if (table.getTable("weather")) |item| {
            std.log.debug("'weather' from toml file.", .{});
            var wea = device.Weather{
                .icon = item.getString("icon") orelse " ",
                .location = item.getString("location") orelse "Buenos+Aires",
                .name = item.getString("name") orelse "WEA",
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1_800_000)),
            };
            try devices_list.append(wea.toDevice());
            size += 1;
        }
        if (table.getTable("script")) |item| {
            std.log.debug("'script' from toml file.", .{});
            var script = device.Script{
                .icon = item.getString("icon") orelse return error.ScriptIconRequired,
                .name = item.getString("name") orelse return error.ScriptNameRequired,
                .path = item.getString("path") orelse return error.ScriptPathRequired,
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1_000)),
            };
            try devices_list.append(script.toDevice());
            size += 1;
        }
        if (table.getTable("date")) |item| {
            std.log.debug("'date' from toml file.", .{});
            var date = device.Date{
                .icon = item.getString("icon") orelse " ",
                .format = try std.fmt.allocPrintZ(allocator, "{s}", .{item.getString("format") orelse "%A %d/%m/%Y %H:%M:%S"}),
                .time = @as(u64, @intCast(item.getInteger("time") orelse 1_000)),
            };
            try devices_list.append(date.toDevice());
            size += 1;
        }
    } else |_| {
        std.log.debug("Configuraiton toml file does not exist. Applying default", .{});
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
        size = 6;
    }

    try execute(&devices_list, size);

    if (toml != null) toml.?.deinit(allocator);

    return error.InitializationError;
}

fn execute(devices_list: *std.ArrayList(device.Device), size: usize) !void {
    std.log.debug("Preparing threads...", .{});
    var devices = try devices_list.toOwnedSlice();

    const threads = try std.heap.page_allocator.alloc(std.Thread, size);
    defer std.heap.page_allocator.free(threads);

    for (devices, 0..) |*dev, i| {
        threads[i] = try std.Thread.spawn(.{}, statusbar.threadDevice, .{dev});
    }

    std.log.debug("Executing {d} threads.", .{size});
    const tbar = try std.Thread.spawn(.{}, statusbar.threadStatusBar, .{&devices});
    for (threads) |thread| {
        thread.join();
    }
    tbar.join();
}
