const std = @import("std");
const types = @import("types.zig");
const config = @import("config.zig");

pub const EngineState = struct {
    currentState: ActionStates,

    pub fn init() EngineState {
        return EngineState{
            .currentState = ActionStates.init(),
        };
    }

    pub fn update(self: *@This(), keys: types.KeyboardStatus) !std.BoundedArray(types.Action, types.enumSize(types.Action)) {
        var triggeredActions = std.BoundedArray(types.Action, types.enumSize(types.Action)){};
        var downActions = std.BoundedArray(types.Action, types.enumSize(types.Action)){};

        var cancelActionDown = false;

        for (types.ACTIONS) |action| {
            const mapping = config.ACTION_MAPPINGS.get(action) orelse continue;
            const previousState = self.currentState.getState(action);
            const isDown = isActionDown(keys, mapping);

            if (!isDown) {
                self.currentState.setState(action, .off);
                if (previousState == .on) {
                    try triggeredActions.append(action);
                }
            } else {
                if (action == .cancel_all) {
                    cancelActionDown = true;
                }

                if (isExcludeDown(keys, mapping)) {
                    self.currentState.setState(action, .cancelled);
                }

                try downActions.append(action);
            }
        }

        if (cancelActionDown or getDownCount(keys) >= config.CANCEL_COUNT) {
            for (downActions.slice()) |action| {
                self.currentState.setState(action, .cancelled);
            }
        }

        // reseting state when all keys are up
        // (just in case I missed something)
        if (downActions.slice().len == 0) {
            self.currentState.reset();
            return triggeredActions;
        }

        for (downActions.slice()) |a| {
            const mappingA = config.ACTION_MAPPINGS.get(a) orelse continue;
            var hasConflict = false;
            for (downActions.slice()) |b| {
                const mappingB = config.ACTION_MAPPINGS.get(b) orelse continue;

                const diff = compareButtons(mappingA.buttons, mappingB.buttons);
                switch (diff) {
                    .identical, .distinct, .a_is_superset => {},
                    .conflict, .b_is_superset => {
                        hasConflict = true;
                        break;
                    },
                }
            }

            if (hasConflict) {
                self.currentState.setState(a, .cancelled);
            } else {
                const current = self.currentState.getState(a);
                if (current == .off) {
                    self.currentState.setState(a, .on);
                }
            }
        }

        return triggeredActions;
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
    for (types.BUTTONS) |button| {
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
        if (std.mem.containsAtLeastScalar(types.Button, bButtons, 1, e)) {
            common_buttons += 1;
        } else {
            only_in_a += 1;
        }
    }
    for (bButtons) |e| {
        if (!std.mem.containsAtLeastScalar(types.Button, aButtons, 1, e)) {
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

var testIdx: i32 = 0;

fn test_step(state: *EngineState, new_status: std.enums.EnumFieldStruct(types.Button, bool, false), expect_actions: []const types.Action) !void {
    var res = try state.update(std.EnumArray(types.Button, bool).initDefault(false, new_status));
    std.debug.print("{d}: ", .{testIdx});
    for (res.slice()) |i| {
        std.debug.print("{s}, ", .{@tagName(i)});
    }
    std.debug.print("\n", .{});
    std.debug.print("{d}___: ", .{testIdx});
    var iterator = state.currentState.content.iterator();
    while (iterator.next()) |e| {
        if (e.value.* != .off) {
            std.debug.print("{s}:{s}, ", .{ @tagName(e.key), @tagName(e.value.*) });
        }
    }
    std.debug.print("\n", .{});
    try std.testing.expect(std.mem.eql(types.Action, res.slice(), expect_actions));
    testIdx += 1;
}
