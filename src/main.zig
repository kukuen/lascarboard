const arduino = @import("arduino");

const std = @import("std");
const config = @import("config.zig");
const types = @import("types.zig");
const engine = @import("engine.zig");
const crg = @import("crg.zig");

var keyboard_debouncer: types.KeyboardDebouncer = undefined;
var engine_state: engine.EngineState = undefined;

var last_keys_pressed_count: u8 = 0;
var last_time: u32 = 0;

pub export fn setup() callconv(.c) void {
    arduino.keyboardBegin();

    if (config.debug_serial) {
        arduino.serialBegin(9600);
        arduino.delay(5000);
    }

    arduino.pinMode(config.arduino_pins.debug_led, arduino.OUTPUT);

    engine_state = engine.EngineState.init();
    keyboard_debouncer = types.KeyboardDebouncer.init();

    inline for (types.all_buttons) |button| {
        const pin = config.arduino_pins.buttons.get(button);
        if (pin) |p| {
            arduino.pinMode(p, arduino.INPUT_PULLUP);
        }
    }

    updateKeyboardStateRaw();

    var keyboard_status = keyboard_debouncer.getKeyboardStatus();

    if (engine.getDownCount(keyboard_status) >= config.action_write_config_keys_down) {
        // needed because keyboard isn't recognized right away
        arduino.delay(1000);
        crg.writeConfig();

        while (engine.getDownCount(keyboard_status) > 0) {
            updateKeyboardStateRaw();
            keyboard_status = keyboard_debouncer.getKeyboardStatus();
        }
    }

    last_time = @intCast(arduino.micros());
}

pub export fn loop() callconv(.c) void {
    const now: u32 = @intCast(arduino.micros());
    // handling time wrapping with -%
    const delta: u32 = now -% last_time;
    last_time = now;

    inline for (types.all_buttons) |button| {
        const pin = config.arduino_pins.buttons.get(button);
        if (pin) |p| {
            keyboard_debouncer.getKey(button).update(arduino.digitalRead(p) == 0, delta);
        }
    }

    const keyboardStatus = keyboard_debouncer.getKeyboardStatus();

    const actions = engine_state.update(keyboardStatus);

    for (actions.items()) |action| {
        const key = config.crg.shortcuts.get(action);
        if (key) |k| {
            arduino.keyboardPress(k.key);
            arduino.keyboardRelease(k.key);
        }
    }

    const keys_pressed_count = engine.getDownCount(keyboardStatus);

    arduino.digitalWrite(config.arduino_pins.debug_led, if (keys_pressed_count > 0) 1 else 0);

    if (config.debug_serial and keys_pressed_count != last_keys_pressed_count) {
        last_keys_pressed_count = keys_pressed_count;
        var buf: [50]u8 = undefined;
        arduino.serialPrintln(std.mem.printSentinel(&buf, "keys pressed = {d}", .{keys_pressed_count}, 0) catch "");
    }
}

fn updateKeyboardStateRaw() void {
    inline for (types.all_buttons) |button| {
        const pin = config.arduino_pins.buttons.get(button);
        if (pin) |p| {
            keyboard_debouncer.getKey(button).state = arduino.digitalRead(p) == 0;
        }
    }
}
