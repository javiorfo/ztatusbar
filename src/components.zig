const std = @import("std");
const sys = @import("syslinfo");

pub const Cpu = struct {
    name: []const u8 = "CPU",
    icon: []const u8 = " ",
    time: usize = 1000,
    allocator: std.mem.Allocator = std.heap.page_allocator,
    result: []const u8 = "",

    pub fn convert(ptr: *anyopaque) anyerror!void {
        const self: *Cpu = @ptrCast(@alignCast(ptr));
        const p = sys.cpu.percentageUsed() catch 0;
        self.result = try std.fmt.allocPrint(self.allocator, "{s} {s} {d:.0}% ", .{ self.icon, self.name, p });
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Cpu = @ptrCast(@alignCast(ptr));
        self.allocator.free(self.result);
    }

    pub fn toExecutor(self: *Cpu) Executor {
        return .{
            .ptr = self,
            .convertFn = Cpu.convert,
            .deinitFn = Cpu.deinit,
            .time = &self.time,
            .allocator = &self.allocator,
            .result = &self.result,
        };
    }
};

pub const Volume = struct {
    name: []const u8 = "VOL",
    icon: []const u8 = " ",
    icon_muted: []const u8 = "󰖁 ",
    time: usize = 100,
    allocator: std.mem.Allocator = std.heap.page_allocator,
    result: []const u8 = "",

    pub fn convert(ptr: *anyopaque) anyerror!void {
        const self: *Volume = @ptrCast(@alignCast(ptr));
        const p = try sys.volume.state(.{});
        if (!p.muted) {
            self.result = try std.fmt.allocPrint(self.allocator, "{s} {s} {d}% ", .{ self.icon, self.name, p.volume });
        } else {
            self.result = try std.fmt.allocPrint(self.allocator, "{s} MUTED ", .{self.icon_muted});
        }
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Volume = @ptrCast(@alignCast(ptr));
        self.allocator.free(self.result);
    }

    pub fn toExecutor(self: *Volume) Executor {
        return .{
            .ptr = self,
            .convertFn = Volume.convert,
            .deinitFn = Volume.deinit,
            .time = &self.time,
            .allocator = &self.allocator,
            .result = &self.result,
        };
    }
};

pub const Memory = struct {
    name: []const u8 = "RAM",
    icon: []const u8 = " ",
    time: usize = 1000,
    allocator: std.mem.Allocator = std.heap.page_allocator,
    result: []const u8 = "",

    pub fn convert(ptr: *anyopaque) anyerror!void {
        const self: *Memory = @ptrCast(@alignCast(ptr));
        const m = try sys.memory.usage();
        const p = m.percentageUsed() catch 0;
        self.result = try std.fmt.allocPrint(self.allocator, "{s} {s} {d:.0}% ", .{ self.icon, self.name, p });
    }

    pub fn deinit(ptr: *anyopaque) void {
        const self: *Cpu = @ptrCast(@alignCast(ptr));
        self.allocator.free(self.result);
    }

    pub fn toExecutor(self: *Memory) Executor {
        return .{
            .ptr = self,
            .convertFn = Memory.convert,
            .deinitFn = Memory.deinit,
            .time = &self.time,
            .allocator = &self.allocator,
            .result = &self.result,
        };
    }
};

pub const Executor = struct {
    ptr: *anyopaque,
    convertFn: *const fn (*anyopaque) anyerror!void,
    deinitFn: *const fn (*anyopaque) void,
    time: *usize,
    allocator: *std.mem.Allocator,
    result: *[]const u8,

    pub fn convert(self: Executor) anyerror!void {
        return self.convertFn(self.ptr);
    }

    pub fn deinit(self: Executor) void {
        return self.deinitFn(self.ptr);
    }
};