const std = @import("std");
const config = @import("config.zig");

pub const Button = enum {
    stop,
    timeout,
    start,
    team1,
    team2,
    score,
    f1,
    f2,
    f3,
    f4,
};

pub const BUTTONS = enumList(Button);

pub const Action = enum {
    team1_trip_score_4,
    team1_trip_score_3,
    team1_trip_score_2,
    team1_trip_score_1,
    team1_trip_score_0,

    team1_lead,
    team1_lost,
    team1_star_pass,
    team1_no_initial,

    team1_box_jam,
    team1_box_pivot,

    team2_trip_score_4,
    team2_trip_score_3,
    team2_trip_score_2,
    team2_trip_score_1,
    team2_trip_score_0,

    team2_lead,
    team2_lost,
    team2_star_pass,
    team2_no_initial,

    team2_box_jam,
    team2_box_pivot,

    start_jam,
    stop_jam,
    timeout,

    cancel_all,
};

pub const ACTIONS = enumList(Action);

pub const KeyboardStatus = std.EnumArray(Button, bool);

pub const KeyDebouncer = struct {
    state: bool = false,
    lastRead: bool = false,
    debounceDuration: u32 = 0,

    pub fn update(self: *@This(), read: bool, delta: u32) void {
        if (read != self.lastRead) {
            self.debounceDuration = 0;
            self.lastRead = read;
        } else if (read != self.state) {
            self.debounceDuration += delta;
        }

        if (self.debounceDuration >= config.DEBOUNCE_DELAY_MICROS) {
            self.state = read;
        }
    }
};

pub const KeyboardDebouncer = struct {
    content: std.EnumArray(Button, KeyDebouncer),

    pub fn init() KeyboardDebouncer {
        return .{
            .content = std.EnumArray(Button, KeyDebouncer).initFill(KeyDebouncer{}),
        };
    }

    pub fn getKey(self: *@This(), button: Button) *KeyDebouncer {
        return self.content.getPtr(button);
    }

    pub fn getKeyboardStatus(self: *const @This()) KeyboardStatus {
        var status = KeyboardStatus.initFill(false);
        for (BUTTONS) |button| {
            status.set(button, self.content.get(button).state);
        }
        return status;
    }
};

pub const ActionMapping = struct {
    buttons: []const Button,
    exclude: []const Button = &.{},
};

pub const ShortcutMapping = struct {
    key: u8,
    crg: []const u8,
};

pub fn enumSize(T: type) usize {
    return std.meta.fields(T).len;
}

pub fn enumList(T: type) [enumSize(T)]T {
    const fields = std.meta.fields(T);
    var res: [fields.len]T = undefined;

    inline for (fields, 0..) |f, i| {
        res[i] = @enumFromInt(f.value);
    }

    return res;
}
