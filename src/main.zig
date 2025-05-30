const hal = @cImport(@cInclude("hal.h"));

const std = @import("std");
const config = @import("config.zig");
const types = @import("types.zig");
const engine = @import("engine.zig");
const crg = @import("crg.zig");

const HIGH = 0x1;
const LOW = 0x0;

const INPUT = 0x0;
const OUTPUT = 0x1;
const INPUT_PULLUP = 0x2;

var KEYBOARD_DEBOUNCER: types.KeyboardDebouncer = undefined;
var ENGINE_STATE: engine.EngineState = undefined;

var LAST_KEY_COUNT: u8 = 0;
var LAST_TIME: u32 = 0;

pub export fn setup() callconv(.C) void {
    hal.keyboardBegin();

    if (config.DEBUG_SERIAL) {
        // hal.serialBegin(9600);
        // hal.delay(5000);
    }
    if (config.DEBUG_LED) {
        hal.pinMode(13, OUTPUT);
    }

    ENGINE_STATE = engine.EngineState.init();
    KEYBOARD_DEBOUNCER = types.KeyboardDebouncer.init();

    inline for (types.BUTTONS) |button| {
        const pin = config.PIN_MAPPING.get(button);
        if (pin) |p| {
            hal.pinMode(p, INPUT_PULLUP);
        }
    }

    updateKeyboardStateRaw();

    var keyboardStatus = KEYBOARD_DEBOUNCER.getKeyboardStatus();

    if (engine.getDownCount(keyboardStatus) >= config.KEYS_TO_WRITE_CONFIG) {
        // needed because keyboard isn't recognized right away
        hal.delay(1000);
        crg.writeConfig();

        while (engine.getDownCount(keyboardStatus) > 0) {
            updateKeyboardStateRaw();
            keyboardStatus = KEYBOARD_DEBOUNCER.getKeyboardStatus();
        }
    }

    LAST_TIME = hal.micros();
}

pub export fn loop() callconv(.C) void {
    const now = hal.micros();
    const delta: u32 = if (now < LAST_TIME) std.math.maxInt(u32) - LAST_TIME + now + 1 else now - LAST_TIME;

    if (config.DEBUG_SERIAL) {
        var buf: [50]u8 = undefined;
        hal.serialPrintln(std.fmt.bufPrintZ(&buf, "delta = {d}", .{delta}) catch "");
    }

    LAST_TIME = now;

    inline for (types.BUTTONS) |button| {
        const pin = config.PIN_MAPPING.get(button);
        if (pin) |p| {
            KEYBOARD_DEBOUNCER.getKey(button).update(hal.digitalRead(p) == 0, delta);
        }
    }

    const keyboardStatus = KEYBOARD_DEBOUNCER.getKeyboardStatus();

    const newCount = engine.getDownCount(keyboardStatus);

    if (config.DEBUG_LED) {
        hal.digitalWrite(13, if (newCount > 0) 1 else 0);
    }

    // if (config.DEBUG_SERIAL and newCount != LAST_KEY_COUNT) {
    //     LAST_KEY_COUNT = newCount;
    //     var buf: [50]u8 = undefined;
    //     hal.serialPrintln(std.fmt.bufPrintZ(&buf, "count = {d}", .{newCount}) catch "");
    // }

    const actions = ENGINE_STATE.update(keyboardStatus) catch return;

    for (actions.slice()) |action| {
        const key = config.SHORTCUTS.get(action);
        if (key) |k| {
            hal.keyboardPress(k.key);
            hal.keyboardRelease(k.key);
        }
    }
}

fn updateKeyboardStateRaw() void {
    inline for (types.BUTTONS) |button| {
        const pin = config.PIN_MAPPING.get(button);
        if (pin) |p| {
            KEYBOARD_DEBOUNCER.getKey(button).state = hal.digitalRead(p) == 0;
        }
    }
}
