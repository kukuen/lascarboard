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

pub const all_buttons = std.enums.values(Button);

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

pub const all_actions = std.enums.values(Action);

pub const KeyboardStatus = std.EnumArray(Button, bool);

pub const KeyDebouncer = struct {
    state: bool = false,
    last_read: bool = false,
    debounce_duration: u32 = 0,

    pub fn update(self: *@This(), read: bool, delta: u32) void {
        if (read != self.last_read) {
            self.debounce_duration = 0;
            self.last_read = read;
        } else if (read != self.state) {
            self.debounce_duration += delta;
        }

        if (self.debounce_duration >= config.keys_debounce_delay_micros) {
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
        for (all_buttons) |button| {
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

pub fn SimpleBoundedArray(comptime T: type, comptime len: usize) type {
    return struct {
        buffer: [len]T,
        len: usize = 0,

        pub const empty: @This() = .{ .buffer = undefined };

        pub fn append(self: *@This(), e: T) void {
            std.debug.assert(self.len < len);
            self.buffer[self.len] = e;
            self.len += 1;
        }

        pub fn items(self: *const @This()) []const T {
            return self.buffer[0..self.len];
        }
    };
}
