const std = @import("std");
const types = @import("types.zig");
const config = @import("config.zig");

pub const EngineState = struct {
    current_state: ActionStates,

    pub fn init() EngineState {
        return EngineState{
            .current_state = ActionStates.init(),
        };
    }

    pub fn update(self: *@This(), keys: types.KeyboardStatus) types.SimpleBoundedArray(types.Action, types.all_actions.len) {
        var triggered_actions: types.SimpleBoundedArray(types.Action, types.all_actions.len) = .empty;
        var down_actions: types.SimpleBoundedArray(types.Action, types.all_actions.len) = .empty;

        var cancel_action_down = false;

        for (types.all_actions) |action| {
            const mapping = config.actions_mapping.get(action) orelse continue;
            const previous_state = self.current_state.getState(action);
            const is_down = isActionDown(keys, mapping);

            if (!is_down) {
                self.current_state.setState(action, .off);
                if (previous_state == .on) {
                    triggered_actions.append(action);
                }
            } else {
                if (action == .cancel_all) {
                    cancel_action_down = true;
                }

                if (isExcludeDown(keys, mapping)) {
                    self.current_state.setState(action, .cancelled);
                }

                down_actions.append(action);
            }
        }

        if (cancel_action_down or getDownCount(keys) >= config.action_cancel_keys_down) {
            for (down_actions.items()) |action| {
                self.current_state.setState(action, .cancelled);
            }
        }

        // resetting state when all keys are up
        // (just in case I missed something)
        if (down_actions.items().len == 0) {
            self.current_state.reset();
            return triggered_actions;
        }

        for (down_actions.items()) |a| {
            const mapping_a = config.actions_mapping.get(a) orelse continue;
            var has_conflict = false;
            for (down_actions.items()) |b| {
                const mappingB = config.actions_mapping.get(b) orelse continue;

                const diff = compareButtons(mapping_a.buttons, mappingB.buttons);
                switch (diff) {
                    .identical, .distinct, .a_is_superset => {},
                    .conflict, .b_is_superset => {
                        has_conflict = true;
                        break;
                    },
                }
            }

            if (has_conflict) {
                self.current_state.setState(a, .cancelled);
            } else {
                const current = self.current_state.getState(a);
                if (current == .off) {
                    self.current_state.setState(a, .on);
                }
            }
        }

        return triggered_actions;
    }
};

pub fn testErr(i: u8) !void {
    if (5 > i) {
        return error.Test;
    }
}

const ActionState = enum {
    off,
    on,
    cancelled,
};

const ActionStates = struct {
    content: std.EnumArray(types.Action, ActionState),

    pub fn init() ActionStates {
        return ActionStates{
            .content = std.EnumArray(types.Action, ActionState).initFill(.off),
        };
    }

    pub fn reset(self: *@This()) void {
        self.content = std.EnumArray(types.Action, ActionState).initFill(.off);
    }

    fn getState(self: *@This(), e: types.Action) ActionState {
        return self.content.get(e);
    }

    fn setState(self: *@This(), e: types.Action, state: ActionState) void {
        self.content.set(e, state);
    }
};

pub fn isActionDown(status: types.KeyboardStatus, action: types.ActionMapping) bool {
    for (action.buttons) |b| {
        const pressed = status.get(b);
        if (!pressed) return false;
    }

    return true;
}

pub fn isExcludeDown(status: types.KeyboardStatus, action: types.ActionMapping) bool {
    for (action.exclude) |b| {
        const pressed = status.get(b);
        if (pressed) return true;
    }

    return false;
}

pub fn getDownCount(status: types.KeyboardStatus) u8 {
    var count: u8 = 0;
    for (types.all_buttons) |button| {
        if (status.get(button)) {
            count += 1;
        }
    }
    return count;
}

const CompareResult = enum {
    distinct,
    identical,
    conflict,
    a_is_superset,
    b_is_superset,
};

fn compareButtons(aButtons: []const types.Button, bButtons: []const types.Button) CompareResult {
    var common_buttons: u8 = 0;
    var only_in_a: u8 = 0;
    var only_in_b: u8 = 0;

    for (aButtons) |e| {
        if (std.mem.containsAtLeastScalar(types.Button, bButtons, e, 1)) {
            common_buttons += 1;
        } else {
            only_in_a += 1;
        }
    }
    for (bButtons) |e| {
        if (!std.mem.containsAtLeastScalar(types.Button, aButtons, e, 1)) {
            only_in_b += 1;
        }
    }

    if (common_buttons == aButtons.len and common_buttons == bButtons.len) {
        return .identical;
    } else if (common_buttons == 0) {
        return .distinct;
    } else if (only_in_a > 0 and only_in_b == 0) {
        return .a_is_superset;
    } else if (only_in_b > 0 and only_in_a == 0) {
        return .b_is_superset;
    } else {
        return .conflict;
    }
}

test "compare buttons" {
    try std.testing.expectEqual(
        compareButtons(&[_]types.Button{.team1}, &[_]types.Button{.team1}),
        .identical,
    );
    try std.testing.expectEqual(
        compareButtons(&[_]types.Button{ .team1, .score }, &[_]types.Button{ .team1, .score, .f1 }),
        .b_is_superset,
    );
    try std.testing.expectEqual(
        compareButtons(&[_]types.Button{ .team1, .score, .f1 }, &[_]types.Button{ .team1, .score }),
        .a_is_superset,
    );
    try std.testing.expectEqual(
        compareButtons(&[_]types.Button{.team1}, &[_]types.Button{.team2}),
        .distinct,
    );
    try std.testing.expectEqual(
        compareButtons(&[_]types.Button{ .team1, .score }, &[_]types.Button{ .team2, .score }),
        .conflict,
    );
}

test {
    var state = EngineState.init();

    try test_step(&state, .{ .start = true }, &[_]types.Action{});
    try test_step(&state, .{}, &[_]types.Action{.start_jam});

    try test_step(&state, .{ .start = true, .timeout = true }, &[_]types.Action{});
    try test_step(&state, .{ .timeout = true }, &[_]types.Action{});
    try test_step(&state, .{}, &[_]types.Action{});

    try test_step(&state, .{ .team1 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true }, &[_]types.Action{.team1_trip_score_4});

    try test_step(&state, .{ .team1 = true, .score = true, .start = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true }, &[_]types.Action{ .team1_trip_score_4, .start_jam });

    try test_step(&state, .{ .team1 = true, .score = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .score = true }, &[_]types.Action{.team1_trip_score_3});
    try test_step(&state, .{ .team1 = true }, &[_]types.Action{});

    try test_step(&state, .{ .team1 = true, .score = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .f1 = true }, &[_]types.Action{.team1_trip_score_3});
    try test_step(&state, .{ .team1 = true }, &[_]types.Action{});

    try test_step(&state, .{ .team1 = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true }, &[_]types.Action{.team1_lead});

    try test_step(&state, .{ .team1 = true, .team2 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .team2 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .team2 = true }, &[_]types.Action{});

    try test_step(&state, .{}, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .f1 = true, .f2 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .f1 = false, .f2 = false }, &[_]types.Action{.team1_box_jam});

    try test_step(&state, .{ .team1 = true, .f1 = true, .f2 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .score = false }, &[_]types.Action{});

    try test_step(&state, .{ .team1 = true, .f1 = true, .f2 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .score = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .score = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true }, &[_]types.Action{.team1_trip_score_3});
    try test_step(&state, .{ .team1 = true, .team2 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{ .team2 = true, .score = true }, &[_]types.Action{});
    try test_step(&state, .{}, &[_]types.Action{});

    try test_step(&state, .{ .team1 = true, .f2 = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team1 = true, .team2 = true, .f2 = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team2 = true, .f2 = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team2 = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team2 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team2 = true, .f2 = true, .f1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .team2 = true }, &[_]types.Action{.team2_box_jam});

    try test_step(&state, .{ .start = true, .team1 = true }, &[_]types.Action{});
    try test_step(&state, .{ .start = true, .team1 = true, .score = true, .f1 = true, .f2 = true, .f3 = true, .f4 = true }, &[_]types.Action{});
    try test_step(&state, .{ .start = true, .team1 = true }, &[_]types.Action{});
    try test_step(&state, .{}, &[_]types.Action{});
}

var test_idx: i32 = 0;

fn test_step(state: *EngineState, new_status: std.enums.EnumFieldStruct(types.Button, bool, false), expect_actions: []const types.Action) !void {
    var res = try state.update(std.EnumArray(types.Button, bool).initDefault(false, new_status));
    std.debug.print("{d}: ", .{test_idx});
    for (res.slice()) |i| {
        std.debug.print("{s}, ", .{@tagName(i)});
    }
    std.debug.print("\n", .{});
    std.debug.print("{d}___: ", .{test_idx});
    var iterator = state.current_state.content.iterator();
    while (iterator.next()) |e| {
        if (e.value.* != .off) {
            std.debug.print("{s}:{s}, ", .{ @tagName(e.key), @tagName(e.value.*) });
        }
    }
    std.debug.print("\n", .{});
    try std.testing.expect(std.mem.eql(types.Action, res.slice(), expect_actions));
    test_idx += 1;
}
