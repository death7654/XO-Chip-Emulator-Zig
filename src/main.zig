const std = @import("std");
const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const cpu = @import("Emulator/CPU/cpu.zig");
const emulator = @import("Emulator/emulator.zig");
const input = @import("Emulator/input/input.zig");
const display = @import("Emulator/display/display.zig");
const audio = @import("Emulator/audio/audio.zig");

pub fn main() !void {
    emulator.emulator.init();
    try emulator.emulator.load_rom("ROMS/programs/Random Number Test [Matthew Mikolay, 2010].ch8");
    defer display.display.deinit();
    defer audio.audio.deinit();

    const cycles_per_frame: f64 = 700.0 / 60.0;
    var cycle_acc: f64 = 0.0;

    while (!cpu.CPU.exit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => cpu.CPU.exit = true,
                sdl.SDL_KEYDOWN, sdl.SDL_KEYUP => {
                    const pressed = event.type == sdl.SDL_KEYDOWN;
                    const key: ?u4 = switch (event.key.keysym.sym) {
                        // map keys
                        sdl.SDLK_KP_0 => 0x0,
                        sdl.SDLK_KP_1 => 0x1,
                        sdl.SDLK_KP_2 => 0x2,
                        sdl.SDLK_KP_3 => 0x3,
                        sdl.SDLK_KP_4 => 0x4,
                        sdl.SDLK_KP_5 => 0x5,
                        sdl.SDLK_KP_6 => 0x6,
                        sdl.SDLK_KP_7 => 0x7,
                        sdl.SDLK_KP_8 => 0x8,
                        sdl.SDLK_KP_9 => 0x9,
                        sdl.SDLK_a => 0xA,
                        sdl.SDLK_b => 0xB,
                        sdl.SDLK_c => 0xC,
                        sdl.SDLK_d => 0xD,
                        sdl.SDLK_e => 0xE,
                        sdl.SDLK_f => 0xF,
                        else => null,
                    };
                    if (key) |k| {
                        input.input.last_keys[k] = input.input.keys[k];
                        input.input.keys[k] = pressed;
                    }
                },
                else => {},
            }
        }

        cycle_acc += cycles_per_frame;
        while (cycle_acc >= 1.0) {
            // execute routines for every frame
            emulator.emulator.step();
            cycle_acc -= 1.0;
        }

        // decrease timers
        emulator.emulator.tick_timers();
        display.display.render();
    }
}
