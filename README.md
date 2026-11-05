# Lascarboard

An arduino-based shortcuts box for Scoreboard operators to control [CRG](https://github.com/rollerderby/scoreboard).

## Features

- ~25 shortcuts mapped on 10 buttons
- Simulates a keyboard 

## Board Layout

```
                      (left hand)      (right hand)

[stop] [timeout] [start] [team 1]      [f1   ] [f2] [f3] [f4]
                         [team 2]      [score]                        
```

## Shortcuts

### Timers
- `[stop]`: Stop the jam
- `[timeout]`: Start a new timeout
- `[start]`: Start the jam

### Scoring

Combine a `[team]` button + 1 `[score]` button + additional `[f]` buttons. 
The numbers of score buttons pressed is the number of points.

- `[team N] + [score]`: +1 point
- `[team N] + [score] + [f1]`: +2 points
- `[team N] + [score] + [f1] + [f2]`: +3 points
- `[team N] + [score] + [f1] + [f2] + [f3]`: +4 points
- `[team N] + [f4]`: +0 point

### Actions

Combine a `[team]` button + 1 (or more) `[f]` buttons

- `[team N] + [f1]`: Lead
- `[team N] + [f2]`: Lead lost
- `[team N] + [f3]`: Star pass
- `[team N] + [f4]`: No initial
- `[team N] + [f1] + [f2]`: Jammer in box
- `[team N] + [f3] + [f4]`: Pivot in box

### Configure CRG

1. Open a text editor
2. Press 5 buttons while plugging the controller to the computer
3. The board will automatically type the configuration *(you can release the keys as soon as it starts typing)*
4. Save the json configuration, and import it into CRG

## Requirements

- Zig 0.17.1
- Platform.IO

## Building from source

```
zig build
pio run -t upload
```

## Hardware

Wire the 10 buttons to the Arduino board according to `PIN_MAPPING` in [config.zig](src/config.zig).


