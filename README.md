# zig-bytebeat

Evaluates bytebeat formulas and writes unsigned 8-bit samples to stdout (or a
wav file with `-o`).

    zig build -Doptimize=ReleaseFast
    ./zig-out/bin/bytebeat "t*(t>>5|t>>8)" 8000 30 | aplay -r 8000 -f U8
    ./zig-out/bin/bytebeat -o out.wav "t&t>>8" 8000 10

Arguments: formula, sample rate, seconds. The variable is `t`. Supported:
`+ - * / % & | ^ << >> < > ==`, parentheses, integer literals. All
arithmetic is on u32 and wraps. `formulas.txt` has a few to try.
