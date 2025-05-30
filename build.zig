const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .avr,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{
            .explicit = &std.Target.avr.cpu.atmega32u4,
        },
    });

    const lib = b.addStaticLibrary(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });

    lib.addSystemIncludePath(b.path("src"));

    b.installArtifact(lib);

    const upload_step = b.step("upload", "Upload");
    upload_step.dependOn(&b.addSystemCommand(&.{ "platformio", "run", "-t", "upload" }).step);
}
