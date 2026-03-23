# XO-CHIP Emulator

A CHIP-8, SUPER-CHIP, and XO-CHIP emulator written in Zig with SDL2 for display and input.

---

## Features

- Full CHIP-8 instruction set
- SUPER-CHIP support (hires mode, scrolling, large sprites)
- XO-CHIP extensions (two bitplanes, 4-colour display, 64KB memory, audio pattern buffer, 16-bit addressing)
- Lores (64x32) and hires (128x64) display modes

---

## Images
<img width="1602" height="840" alt="image" src="https://github.com/user-attachments/assets/ed6b2f45-30ed-4b58-9303-b0b73b851cc5" />
<img width="1602" height="840" alt="image" src="https://github.com/user-attachments/assets/24182123-c6a4-4895-868e-cb151b4b8882" />
<img width="1602" height="840" alt="image" src="https://github.com/user-attachments/assets/1be187c3-dffd-41f6-a44f-87acb1503227" />



## Requirements

- [Zig](https://ziglang.org/) 0.15.x or later
- SDL2 (fetched automatically via Zig package manager)

---

## Building

Clone the repository:

```bash
git clone https://github.com/yourusername/xo-chip-emulator-zig
cd xo-chip-emulator-zig
```

Fetch dependencies:

```bash
zig fetch --save=SDL git+https://github.com/allyourcodebase/SDL
```

Build and run:

```bash
zig build run
```

---

## ROM

By default the emulator loads from `ROMS/demos/Zero Demo [zeroZshadow, 2007].ch8`. To load a different ROM, change the path in `src/main.zig`:

```zig
try emulator.emulator.load_rom("path/to/your.ch8");
```

ROMs can be found at:
- [CHIP-8 Archive](https://johnearnest.github.io/chip8Archive/) — public domain games and demos
- [chip8-test-suite](https://github.com/Timendus/chip8-test-suite) — test ROMs for verifying emulator accuracy

---


## References

- [Octo IDE & XO-CHIP specification](https://johnearnest.github.io/Octo/)
- [CHIP-8 technical reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
- [chip8-test-suite](https://github.com/Timendus/chip8-test-suite)
- [CHIP-8 Archive](https://johnearnest.github.io/chip8Archive/)

---
