const std = @import("std");
const sys = @import("syslinfo");
const c = @cImport({
    @cInclude("time.h");
});
const sec = @import("section.zig");
const testing = std.testing;

pub const Cpu = struct {
    name: []const u8 = "CPU",
    icon: []const u8 = " ",
    time: usize = 1_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Cpu = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Cpu", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .perc = try sys.cpu.percentageUsed() },
        };

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Cpu) Device {
        return .{
            .ptr = self,
            .refreshFn = Cpu.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Date = struct {
    format: [*c]const u8 = "%A %d/%m/%Y %H:%M:%S",
    icon: []const u8 = " ",
    time: usize = 1_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Date = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Date", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        var now: c.time_t = c.time(null);
        const local: *c.struct_tm = c.localtime(&now);
        var buffer: [80]u8 = undefined;
        const len = c.strftime(&buffer, 80, self.format, local);

        self.section = .{
            .icon = self.icon,
            .name = "",
            .refreshed_value = .{ .str = buffer[0..len] },
        };

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Date) Device {
        return .{
            .ptr = self,
            .refreshFn = Date.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Temperature = struct {
    name: []const u8 = "TEMP",
    icon: []const u8 = "󰏈 ",
    thermal_zone: sys.thermal.ZONE = .zero,
    time: usize = 1_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Temperature = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Temperature", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .degree = try sys.thermal.getTemperatureFromZone(self.thermal_zone) },
        };

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Temperature) Device {
        return .{
            .ptr = self,
            .refreshFn = Temperature.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Memory = struct {
    name: []const u8 = "RAM",
    icon: []const u8 = " ",
    time: usize = 1_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Memory = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Memory", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        const mem_usage = try sys.memory.usage();
        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .perc = try mem_usage.percentageUsed() },
        };

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Memory) Device {
        return .{
            .ptr = self,
            .refreshFn = Memory.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Disk = struct {
    name: []const u8 = "DISK",
    icon: []const u8 = "󰋊 ",
    unit: [:0]const u8 = "/",
    time: usize = 1_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Disk = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Disk", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        const disk_usage = try sys.disk.usage(self.unit);
        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .perc = try disk_usage.percentageUsed() },
        };

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Disk) Device {
        return .{
            .ptr = self,
            .refreshFn = Disk.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Volume = struct {
    name: []const u8 = "VOL",
    icon: []const u8 = " ",
    icon_muted: []const u8 = "󰖁 ",
    time: usize = 100,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Volume = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Volume", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        const volume_state = try sys.volume.state(.{});
        if (!volume_state.muted) {
            self.section = .{
                .icon = self.icon,
                .name = self.name,
                .refreshed_value = .{ .perc = @as(f32, @floatFromInt(volume_state.volume)) },
            };
        } else {
            self.section = .{
                .icon = self.icon_muted,
                .name = "",
                .refreshed_value = .{ .str = "MUTED" },
            };
        }

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Volume) Device {
        return .{
            .ptr = self,
            .refreshFn = Volume.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Network = struct {
    name: []const u8 = "NET",
    icon: []const u8 = "󰀂 ",
    icon_down: []const u8 = "󰯡 ",
    time: usize = 5_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    const posix = std.posix;

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Network = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Network", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        // Google's DNS server on port 53
        const address = try std.net.Address.parseIp("8.8.8.8", 53);
        const tpe: u32 = posix.SOCK.STREAM;
        const protocol = posix.IPPROTO.TCP;

        const socket = try posix.socket(address.any.family, tpe, protocol);
        defer posix.close(socket);

        // Timeout 1 seconds max
        const timeout = posix.timeval{ .tv_sec = 1, .tv_usec = 0 };
        try posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.RCVTIMEO, &std.mem.toBytes(timeout));
        try posix.setsockopt(socket, posix.SOL.SOCKET, posix.SO.SNDTIMEO, &std.mem.toBytes(timeout));

        if (posix.connect(socket, &address.any, address.getOsSockLen())) |_| {
            self.section = .{
                .icon = self.icon,
                .name = "",
                .refreshed_value = .{ .str = self.name },
            };
        } else |_| {
            self.section = .{
                .icon = self.icon_down,
                .name = "",
                .refreshed_value = .{ .str = self.name },
            };
        }

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Network) Device {
        return .{
            .ptr = self,
            .refreshFn = Network.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Battery = struct {
    name: []const u8 = "BAT",
    icon_full: []const u8 = "󰁹",
    icon_half: []const u8 = "󰁿",
    icon_low: []const u8 = "󰁺",
    path: []const u8,
    time: usize = 10_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    const label = "POWER_SUPPLY_CAPACITY=";

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Battery = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Battery", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        var file = try std.fs.openFileAbsolute(self.path, .{});
        defer file.close();

        var buffer: [128]u8 = undefined;
        var percentage: u8 = 0;

        while (try file.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (std.mem.indexOf(u8, line, label) != null) {
                percentage = try std.fmt.parseInt(u8, std.mem.trimRight(u8, line[label.len..], " \t\r\n"), 10);
                break;
            }
        }

        var icon = self.icon_full;
        if (percentage < 30) {
            icon = self.icon_low;
        } else if (percentage < 100) {
            icon = self.icon_half;
        }

        self.section = .{
            .icon = icon,
            .name = self.name,
            .refreshed_value = .{ .perc = @as(f32, @floatFromInt(percentage)) },
        };

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Battery) Device {
        return .{
            .ptr = self,
            .refreshFn = Battery.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Weather = struct {
    name: []const u8 = "WEA",
    icon: []const u8 = " ",
    location: []const u8 = "Buenos+Aires",
    time: usize = 1_800_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Weather = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Weather", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const url = try std.fmt.allocPrintZ(allocator, "wttr.in/{s}?format=%t", .{self.location});

        var child = std.process.Child.init(&.{ "curl", "-s", url }, allocator);

        child.stdin_behavior = .Inherit;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Inherit;

        try child.spawn();

        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .str = "-" },
        };

        const output = try child.stdout.?.readToEndAlloc(allocator, 16);
        defer allocator.free(output);

        const term = try child.wait();

        if (term.Exited != 0) {
            std.log.err("Failed to fetch weather data: {}", .{term.Exited});
        } else {
            self.section.?.refreshed_value.str = output[1..6];
        }

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Weather) Device {
        return .{
            .ptr = self,
            .refreshFn = Weather.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Script = struct {
    name: []const u8,
    icon: []const u8,
    path: []const u8,
    time: usize = 1_000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Script = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Script", .{});
            std.time.sleep(std.time.ns_per_ms * self.time);
        }

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer if (gpa.deinit() != .ok) @panic("leak script");
        const allocator = gpa.allocator();

        var child = std.process.Child.init(&.{ "/bin/sh", self.path }, std.heap.page_allocator);

        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;
        var stdout = std.ArrayList(u8).init(allocator);
        var stderr = std.ArrayList(u8).init(allocator);
        defer {
            stdout.deinit();
            stderr.deinit();
        }

        try child.spawn();
        try child.collectOutput(&stdout, &stderr, 1024);
        const term = try child.wait();

        switch (term) {
            .Exited => |code| {
                self.section = .{
                    .icon = self.icon,
                    .name = self.name,
                    .refreshed_value = .{ .str = if (code == 0) stdout.items else stderr.items },
                };
            },
            else => |err| {
                std.log.err("Error executing script: {}\n", .{err});
            },
        }

        self.mutex.unlock();
        std.time.sleep(std.time.ns_per_ms * self.time);
    }

    pub fn toDevice(self: *Script) Device {
        return .{
            .ptr = self,
            .refreshFn = Script.refresh,
            .time = &self.time,
            .mutex = &self.mutex,
            .section = &self.section,
        };
    }
};

pub const Device = struct {
    ptr: *anyopaque,
    refreshFn: *const fn (*anyopaque) anyerror!void,
    time: *usize,
    mutex: *std.Thread.Mutex,
    section: *?sec.Section,

    pub fn refresh(self: Device) anyerror!void {
        return self.refreshFn(self.ptr);
    }
};

test "cpu" {
    var cpu_test = Cpu{};
    try Cpu.refresh(@ptrCast(&cpu_test));
    try std.testing.expect(cpu_test.section != null);
    try std.testing.expectEqualStrings(@tagName(cpu_test.section.?.refreshed_value), "perc");

    const device = cpu_test.toDevice();
    const ptr_cast: *Cpu = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Cpu, &cpu_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 1_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &cpu_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &cpu_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Cpu.refresh), device.refreshFn);
}

test "date" {
    var date_test = Date{};
    try Date.refresh(@ptrCast(&date_test));
    try std.testing.expect(date_test.section != null);
    try std.testing.expectEqualStrings(@tagName(date_test.section.?.refreshed_value), "str");

    const device = date_test.toDevice();
    const ptr_cast: *Date = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Date, &date_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 1_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &date_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &date_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Date.refresh), device.refreshFn);
}

test "temperature" {
    var temperature_test = Temperature{};
    try Temperature.refresh(@ptrCast(&temperature_test));
    try std.testing.expect(temperature_test.section != null);
    try std.testing.expectEqualStrings(@tagName(temperature_test.section.?.refreshed_value), "degree");

    const device = temperature_test.toDevice();
    const ptr_cast: *Temperature = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Temperature, &temperature_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 1_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &temperature_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &temperature_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Temperature.refresh), device.refreshFn);
}

test "memory" {
    var mem_test = Memory{};
    try Memory.refresh(@ptrCast(&mem_test));
    try std.testing.expect(mem_test.section != null);
    try std.testing.expectEqualStrings(@tagName(mem_test.section.?.refreshed_value), "perc");

    const device = mem_test.toDevice();
    const ptr_cast: *Memory = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Memory, &mem_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 1_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &mem_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &mem_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Memory.refresh), device.refreshFn);
}

test "disk" {
    var disk_test = Disk{};
    try Disk.refresh(@ptrCast(&disk_test));
    try std.testing.expect(disk_test.section != null);
    try std.testing.expectEqualStrings(@tagName(disk_test.section.?.refreshed_value), "perc");

    const device = disk_test.toDevice();
    const ptr_cast: *Disk = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Disk, &disk_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 1_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &disk_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &disk_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Disk.refresh), device.refreshFn);
}

test "volume" {
    var vol_test = Volume{};
    try Volume.refresh(@ptrCast(&vol_test));
    try std.testing.expect(vol_test.section != null);
    try std.testing.expectEqualStrings(@tagName(vol_test.section.?.refreshed_value), "perc");

    const device = vol_test.toDevice();
    const ptr_cast: *Volume = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Volume, &vol_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 100), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &vol_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &vol_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Volume.refresh), device.refreshFn);
}

test "network" {
    var net_test = Network{ .time = 1000 };
    try Volume.refresh(@ptrCast(&net_test));
    try std.testing.expect(net_test.section != null);

    const device = net_test.toDevice();
    const ptr_cast: *Network = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Network, &net_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 1_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &net_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &net_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Network.refresh), device.refreshFn);
}

test "weather" {
    var weather_test = Weather{ .time = 5000 };
    try Weather.refresh(@ptrCast(&weather_test));
    try std.testing.expect(weather_test.section != null);

    const device = weather_test.toDevice();
    const ptr_cast: *Weather = @ptrCast(@alignCast(device.ptr));
    try std.testing.expectEqual(@as(*Weather, &weather_test), ptr_cast);
    try std.testing.expectEqual(@as(usize, 5_000), device.time.*);
    try std.testing.expectEqual(@as(*std.Thread.Mutex, &weather_test.mutex), device.mutex);
    try std.testing.expectEqual(@as(*?sec.Section, &weather_test.section), device.section);
    try std.testing.expectEqual(@as(fn (*anyopaque) anyerror!void, Weather.refresh), device.refreshFn);
}
