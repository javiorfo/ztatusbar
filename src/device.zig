const std = @import("std");
const sys = @import("syslinfo");
const curl = @import("curl");
const c = @cImport({
    @cInclude("time.h");
});
const sec = @import("section.zig");
const testing = std.testing;

pub const Cpu = struct {
    name: []const u8 = "CPU",
    icon: []const u8 = " ",
    time: usize = 1000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Cpu = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Cpu", .{});
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

test "cpu" {
    var cpu_test = Cpu{};
    const dev = cpu_test.toDevice();
    try dev.refresh();
    try testing.expect(cpu_test.section != null);
}

pub const Date = struct {
    format: [*c]const u8 = "%A %d/%m/%Y %H:%M:%S",
    icon: []const u8 = " ",
    time: usize = 1000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Date = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Date", .{});
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
    thermal_zone: sys.thermal.ZONE = .two,
    time: usize = 1000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Temperature = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Temperature", .{});
        }

        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .perc = try sys.thermal.getTemperatureFromZone(self.thermal_zone) },
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

pub const Disk = struct {
    name: []const u8 = "DISK",
    icon: []const u8 = "󰋊 ",
    unit: [:0]const u8 = "/",
    time: usize = 1000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Disk = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Disk", .{});
        }

        const disk_usage = try sys.disk.usage(self.unit);
        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .perc = @as(f32, @floatFromInt(try disk_usage.percentageUsed())) },
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
    time: usize = 5000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Network = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Network", .{});
        }

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        if (std.net.tcpConnectToHost(allocator, "google.com", 443)) |_| {
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

pub const Weather = struct {
    name: []const u8 = "WEA",
    icon: []const u8 = " ",
    location: []const u8 = "Buenos+Aires",
    time: usize = 1800000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Weather = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Weather", .{});
        }

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer if (gpa.deinit() != .ok) @panic("leak curl");
        const allocator = gpa.allocator();

        const easy = try curl.Easy.init(allocator, .{});
        defer easy.deinit();

        const resp = try easy.get(try std.fmt.allocPrintZ(allocator, "wttr.in/{s}?format=%t", .{self.location}));
        defer resp.deinit();

        const value = if (resp.status_code == 200) resp.body.?.items[1..resp.body.?.items.len] else "-";

        self.section = .{
            .icon = self.icon,
            .name = self.name,
            .refreshed_value = .{ .str = value },
        };

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

pub const Memory = struct {
    name: []const u8 = "RAM",
    icon: []const u8 = " ",
    time: usize = 1000,
    mutex: std.Thread.Mutex = .{},
    section: ?sec.Section = null,

    pub fn refresh(ptr: *anyopaque) anyerror!void {
        const self: *Memory = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        errdefer {
            self.mutex.unlock();
            std.log.err("Error running convert in Memory", .{});
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
