const std = @import("std");

const types = @import("types.zig");

pub const DEBUG_LED = true;
pub const DEBUG_SERIAL = false;

pub const DEBOUNCE_DELAY_MICROS = 10_000;
pub const CANCEL_COUNT = 10;

pub const KEYS_TO_WRITE_CONFIG = 5;

pub const CRG_OPERATOR = "lascarboard";

pub const PIN_MAPPING = std.EnumArray(types.Button, ?u8).init(.{
    .stop = 3,
    .timeout = 6,
    .start = 8,
    .team1 = 10,
    .team2 = 11,

    .score = 9,
    .f1 = 12,
    .f2 = 2,
    .f3 = 1,
    .f4 = 0,
});

pub const SHORTCUTS = std.EnumArray(types.Action, ?types.ShortcutMapping).init(.{
    .team1_trip_score_4 = .{ .key = 'f', .crg = "Team1TripScore4" },
    .team1_trip_score_3 = .{ .key = 'g', .crg = "Team1TripScore3" },
    .team1_trip_score_2 = .{ .key = 'h', .crg = "Team1TripScore2" },
    .team1_trip_score_1 = .{ .key = 'j', .crg = "Team1TripScore1" },
    .team1_trip_score_0 = .{ .key = 'k', .crg = "Team1TripScore0" },

    .team1_lead = .{ .key = 'l', .crg = "Team1Lead" },
    .team1_lost = .{ .key = 'm', .crg = "Team1Lost" },
    .team1_star_pass = .{ .key = 'w', .crg = "Team1StarPass" },
    .team1_no_initial = .{ .key = 'x', .crg = "Team1NI" },

    .team1_box_jam = .{ .key = 'c', .crg = "Team1JammerBox" },
    .team1_box_pivot = .{ .key = 'v', .crg = "Team1PivotBox" },

    .team2_trip_score_4 = .{ .key = 'a', .crg = "Team2TripScore4" },
    .team2_trip_score_3 = .{ .key = 'z', .crg = "Team2TripScore3" },
    .team2_trip_score_2 = .{ .key = 'e', .crg = "Team2TripScore2" },
    .team2_trip_score_1 = .{ .key = 'r', .crg = "Team2TripScore1" },
    .team2_trip_score_0 = .{ .key = 'y', .crg = "Team2TripScore0" },

    .team2_lead = .{ .key = 'u', .crg = "Team2Lead" },
    .team2_lost = .{ .key = 'i', .crg = "Team2Lost" },
    .team2_star_pass = .{ .key = 'o', .crg = "Team2StarPass" },
    .team2_no_initial = .{ .key = 'p', .crg = "Team2NI" },

    .team2_box_jam = .{ .key = 'q', .crg = "Team2JammerBox" },
    .team2_box_pivot = .{ .key = 'd', .crg = "Team2PivotBox" },

    .start_jam = .{ .key = 's', .crg = "StartJam" },
    .stop_jam = .{ .key = ' ', .crg = "StopJam" },
    .timeout = .{ .key = 't', .crg = "Timeout" },

    .cancel_all = null,
});

pub const ACTION_MAPPINGS = std.EnumArray(types.Action, ?types.ActionMapping).init(.{
    .team2_box_jam = .{
        .buttons = &.{ .team2, .f1, .f2 },
    },
    .team2_box_pivot = .{
        .buttons = &.{ .team2, .f3, .f4 },
    },
    .team2_trip_score_1 = .{
        .buttons = &.{ .team2, .score },
    },
    .team2_trip_score_2 = .{
        .buttons = &.{ .team2, .score, .f1 },
    },
    .team2_trip_score_3 = .{
        .buttons = &.{ .team2, .score, .f1, .f2 },
    },
    .team2_trip_score_4 = .{
        .buttons = &.{ .team2, .score, .f1, .f2, .f3 },
    },
    .team2_trip_score_0 = .{
        .buttons = &.{ .team2, .score, .f4 },
    },

    .team2_lead = .{
        .buttons = &.{ .team2, .f1 },
    },
    .team2_lost = .{
        .buttons = &.{ .team2, .f2 },
    },
    .team2_star_pass = .{
        .buttons = &.{ .team2, .f3 },
    },
    .team2_no_initial = .{
        .buttons = &.{ .team2, .f4 },
    },
    .team1_box_jam = .{
        .buttons = &.{ .team1, .f1, .f2 },
    },
    .team1_box_pivot = .{
        .buttons = &.{ .team1, .f3, .f4 },
    },
    .team1_trip_score_1 = .{
        .buttons = &.{ .team1, .score },
    },
    .team1_trip_score_2 = .{
        .buttons = &.{ .team1, .score, .f1 },
    },
    .team1_trip_score_3 = .{
        .buttons = &.{ .team1, .score, .f1, .f2 },
    },
    .team1_trip_score_4 = .{
        .buttons = &.{ .team1, .score, .f1, .f2, .f3 },
    },
    .team1_trip_score_0 = .{
        .buttons = &.{ .team1, .score, .f4 },
    },
    .team1_lead = .{
        .buttons = &.{ .team1, .f1 },
    },
    .team1_lost = .{
        .buttons = &.{ .team1, .f2 },
    },
    .team1_star_pass = .{
        .buttons = &.{ .team1, .f3 },
    },
    .team1_no_initial = .{
        .buttons = &.{ .team1, .f4 },
    },
    .start_jam = .{
        .buttons = &.{.start},
        .exclude = &.{ .timeout, .stop },
    },
    .stop_jam = .{
        .buttons = &.{.stop},
        .exclude = &.{ .timeout, .start },
    },
    .timeout = .{
        .buttons = &.{.timeout},
        .exclude = &.{ .start, .stop },
    },
    .cancel_all = .{
        .buttons = &.{ .score, .f1, .f2, .f3, .f4 },
    },
});
