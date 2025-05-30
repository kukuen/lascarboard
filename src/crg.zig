const hal = @cImport(@cInclude("hal.h"));
const std = @import("std");
const types = @import("types.zig");
const config = @import("config.zig");

var BUFFER: [200]u8 = undefined;
pub fn writeConfig() void {
    writeStr("{\n");
    writeStr("\"state\": {\n");

    for (types.ACTIONS, 0..) |action, i| {
        if (config.SHORTCUTS.get(action)) |shortcut| {
            if (i > 0) {
                writeStr(",\n");
            }
            const str = std.fmt.bufPrintZ(
                &BUFFER,
                "\"ScoreBoard.Settings.Setting(ScoreBoard.Operator.{s}.KeyControl.{s})\": \"{c}\"",
                .{
                    config.CRG_OPERATOR,
                    shortcut.crg,
                    shortcut.key,
                },
            ) catch "";
            writeStr(str);
        }
    }
    writeStr("\n");
    writeStr("}\n");
    writeStr("}\n");
}

fn writeStr(str: []const u8) void {
    for (str) |c| {
        hal.keyboardWrite(c);
        hal.delay(1);
    }
}
