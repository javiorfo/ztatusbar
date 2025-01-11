const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ztatusbar",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // SYSLINFO
    const dep = b.dependency("syslinfo", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("syslinfo", dep.module("syslinfo"));
    exe.linkSystemLibrary("asound");

    // TOMLZ
    const tomlz = b.dependency("tomlz", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("tomlz", tomlz.module("tomlz"));

    // LIB C
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/device.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe_unit_tests.root_module.addImport("syslinfo", dep.module("syslinfo"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
