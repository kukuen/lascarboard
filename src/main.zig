const arduino = @import("arduino");

const std = @import("std");
const config = @import("config.zig");
const types = @import("types.zig");
const engine = @import("engine.zig");
const crg = @import("crg.zig");

var keyboard_debouncer: types.KeyboardDebouncer = undefined;
var engine_state: engine.EngineState = undefined;

var last_key_count: u8 = 0;
var last_time: u32 = 0;

pub export fn setup() callconv(.c) void {
    arduino.keyboardBegin();

    if (config.debug_serial) {
        // hal.serialBegin(9600);
        // hal.delay(5000);
    }
    if (config.debug_led) {
        arduino.pinMode(13, arduino.OUTPUT);
    }

    engine_state = engine.EngineState.init();
    keyboard_debouncer = types.KeyboardDebouncer.init();

    inline for (types.all_buttons) |button| {
        const pin = config.pin_mapping.get(button);
        if (pin) |p| {
            arduino.pinMode(p, arduino.INPUT_PULLUP);
        }
    }

    updateKeyboardStateRaw();

    var keyboard_status = keyboard_debouncer.getKeyboardStatus();

    if (engine.getDownCount(keyboard_status) >= config.keys_to_write_config) {
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
    var frame_allocator_buffer: [1024]u8 = undefined;
    var frame_allocator = std.heap.FixedBufferAllocator.init(&frame_allocator_buffer);
    const arena = frame_allocator.allocator();

    const now: u32 = @intCast(arduino.micros());
    const delta: u32 = if (now < last_time) std.math.maxInt(u32) - last_time + now + 1 else now - last_time;

    if (config.debug_serial) {
        var buf: [50]u8 = undefined;
        arduino.serialPrintln(std.fmt.bufPrintZ(&buf, "delta = {d}", .{delta}) catch "");
    }

    last_time = now;

    inline for (types.all_buttons) |button| {
        const pin = config.pin_mapping.get(button);
        if (pin) |p| {
            keyboard_debouncer.getKey(button).update(arduino.digitalRead(p) == 0, delta);
        }
    }

    const keyboardStatus = keyboard_debouncer.getKeyboardStatus();

    const newCount = engine.getDownCount(keyboardStatus);

    if (config.debug_led) {
        arduino.digitalWrite(13, if (newCount > 0) 1 else 0);
    }

    // if (config.DEBUG_SERIAL and newCount != LAST_KEY_COUNT) {
    //     LAST_KEY_COUNT = newCount;
    //     var buf: [50]u8 = undefined;
    //     hal.serialPrintln(std.fmt.bufPrintZ(&buf, "count = {d}", .{newCount}) catch "");
    // }

    const actions = engine_state.update(arena, keyboardStatus) catch return;

    for (actions.items) |action| {
        const key = config.crg_shortcuts.get(action);
        if (key) |k| {
            arduino.keyboardPress(k.key);
            arduino.keyboardRelease(k.key);
        }
    }
}

fn updateKeyboardStateRaw() void {
    inline for (types.all_buttons) |button| {
        const pin = config.pin_mapping.get(button);
        if (pin) |p| {
            keyboard_debouncer.getKey(button).state = arduino.digitalRead(p) == 0;
        }
    }
}
