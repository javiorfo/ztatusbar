const std = @import("std");

pub const RefreshedValue = union(enum) {
    perc: f32,
    degree: f32,
    str: []const u8,
};

pub const Section = struct {
    icon: []const u8,
    name: []const u8,
    refreshed_value: RefreshedValue,

    pub fn format(self: Section, alloc: std.mem.Allocator) []const u8 {
        return switch (self.refreshed_value) {
            .perc => blk: {
                if (self.icon.len == 0 or self.name.len == 0) {
                    break :blk std.fmt.allocPrint(alloc, " {s} {d:.0}% ", .{ if (self.icon.len == 0) self.name else self.icon, self.refreshed_value.perc }) catch " err ";
                } else {
                    break :blk std.fmt.allocPrint(alloc, " {s} {s} {d:.0}% ", .{ self.icon, self.name, self.refreshed_value.perc }) catch " err ";
                }
            },
            .degree => blk: {
                if (self.icon.len == 0 or self.name.len == 0) {
                    break :blk std.fmt.allocPrint(alloc, " {s} {d:.0}°C ", .{ if (self.icon.len == 0) self.name else self.icon, self.refreshed_value.degree }) catch " err ";
                } else {
                    break :blk std.fmt.allocPrint(alloc, " {s} {s} {d:.0}°C ", .{ self.icon, self.name, self.refreshed_value.degree }) catch " err ";
                }
            },
            else => blk: {
                if (self.icon.len == 0 or self.name.len == 0) {
                    break :blk std.fmt.allocPrint(alloc, " {s} {s} ", .{ if (self.icon.len == 0) self.name else self.icon, self.refreshed_value.str }) catch " err ";
                } else {
                    break :blk std.fmt.allocPrint(alloc, " {s} {s} {s} ", .{ self.icon, self.name, self.refreshed_value.str }) catch " err ";
                }
            },
        };
    }
};
