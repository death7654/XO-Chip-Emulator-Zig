const std = @import("std");
const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const cpu = @import("Emulator/CPU/cpu.zig");
const emulator = @import("Emulator/emulator.zig");
const input = @import("Emulator/input/input.zig");
const display = @import("Emulator/display/display.zig");

pub fn main() !void {
    try emulator.emulator.load_rom("ROMS/demos/Sierpinski [Sergey Naydenov, 2010].ch8");
    emulator.emulator.init();
    defer display.display.deinit();

    const cycles_per_frame: usize = 700 / 60;

    while (!cpu.CPU.exit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => cpu.CPU.exit = true,
                sdl.SDL_KEYDOWN, sdl.SDL_KEYUP => {
                    const pressed = event.type == sdl.SDL_KEYDOWN;
                    const key: ?u4 = switch (event.key.keysym.sym) {
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

        var i: usize = 0;
        while (i < cycles_per_frame) : (i += 1) {
            emulator.emulator.step();
        }

        emulator.emulator.tick_timers();
        display.display.render();
    }
}
