const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library shared between all solutions.
    const lib = b.addModule("lib", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    for (1..4) |i| {
        const name = std.fmt.allocPrint(b.allocator, "day{d:02}", .{i}) catch unreachable;
        const file = std.fmt.allocPrint(b.allocator, "src/day/{d:02}.zig", .{i}) catch unreachable;
        const desc = std.fmt.allocPrint(b.allocator, "Run solution for Day {d}", .{i}) catch unreachable;

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(file),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "lib", .module = lib },
                },
            }),
        });

        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        run.step.dependOn(b.getInstallStep());

        const step = b.step(name, desc);
        step.dependOn(&run.step);

        if (b.args) |args| {
            run.addArgs(args);
        }
    }

    // Unit tests for the shared library.
    const tests = b.addTest(.{
        .root_module = lib,
    });

    // A run step that will run the test executable.
    const run_tests = b.addRunArtifact(tests);

    const step_test = b.step("test", "Run unit tests");
    step_test.dependOn(&run_tests.step);
}
