const std = @import("std");

const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .avr,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{
            .explicit = &std.Target.avr.cpu.atmega32u4,
        },
    });

    const optimize = std.builtin.Optimize.fast;

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const translate_c = b.dependency("translate_c", .{});

    {
        const translator = Translator.init(translate_c, .{
            .c_source_file = b.path("arduino/hal.h"),
            .target = target,
            .optimize = optimize,
        });
        root_module.addImport("arduino", translator.mod);
    }

    const lib = b.addLibrary(.{
        .name = "main",
        .root_module = root_module,
    });

    b.installArtifact(lib);

    const upload_step = b.step("upload", "Upload");
    upload_step.dependOn(&b.addSystemCommand(&.{ "platformio", "run", "-t", "upload" }).step);
}
