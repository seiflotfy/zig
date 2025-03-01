const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target: std.zig.CrossTarget = .{ .os_tag = .macos };

    const test_step = b.step("test", "Test");
    test_step.dependOn(b.getInstallStep());

    {
        const exe = b.addExecutable(.{
            .name = "pagezero",
            .optimize = optimize,
            .target = target,
        });
        exe.addCSourceFile("main.c", &.{});
        exe.linkLibC();
        exe.pagezero_size = 0x4000;

        const check = exe.checkObject(.macho);
        check.checkStart("LC 0");
        check.checkNext("segname __PAGEZERO");
        check.checkNext("vmaddr 0");
        check.checkNext("vmsize 4000");

        check.checkStart("segname __TEXT");
        check.checkNext("vmaddr 4000");

        test_step.dependOn(&check.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "no_pagezero",
            .optimize = optimize,
            .target = target,
        });
        exe.addCSourceFile("main.c", &.{});
        exe.linkLibC();
        exe.pagezero_size = 0;

        const check = exe.checkObject(.macho);
        check.checkStart("LC 0");
        check.checkNext("segname __TEXT");
        check.checkNext("vmaddr 0");

        test_step.dependOn(&check.step);
    }
}
