const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Keep tracy enabled by default for the demo; real projects should opt-in explicitly.
    const tracy_enable = b.option(bool, "tracy_enable", "Enable profiling") orelse true;

    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .tracy_enable = tracy_enable,
    });

    const exe = b.addExecutable(.{
        .name = "tracy-mutex-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("tracy", tracy.module("tracy"));
    exe.root_module.linkLibrary(tracy.artifact("tracy"));
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the mutex demo");
    run_step.dependOn(&run_cmd.step);
}
