const arduino = @import("arduino");
const std = @import("std");
const types = @import("types.zig");
const config = @import("config.zig");

var buffer: [200]u8 = @splat(0);

pub fn writeConfig() void {
    writeStr("{\n");
    writeStr("\"state\": {\n");

    for (types.all_actions, 0..) |action, i| {
        if (config.crg_shortcuts.get(action)) |shortcut| {
            if (i > 0) {
                writeStr(",\n");
            }
            const str = std.fmt.bufPrintSentinel(
                &buffer,
                "\"ScoreBoard.Settings.Setting(ScoreBoard.Operator.{s}.KeyControl.{s})\": \"{c}\"",
                .{
                    config.crg_operator,
                    shortcut.crg,
                    shortcut.key,
                },
                0,
            ) catch "";
            writeStr(str);
        }
    }
    writeStr("\n");
    writeStr("}\n");
    writeStr("}\n");
}

fn writeStr(str: [:0]const u8) void {
    for (str) |c| {
        arduino.keyboardWrite(c);
        arduino.delay(1);
    }
}
