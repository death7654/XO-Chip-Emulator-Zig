const std = @import("std");
const memory = @import("../memory/memory.zig");
const display = @import("../display/display.zig");
const input = @import("../input/input.zig");
const audio = @import("../Audio/audio.zig");
const registers: u8 = 16;
const stack_size: u8 = 16;

pub const CPU = struct {
    // set up the intepreter
    pub var pc: u16 = 0x200;
    pub var register: [registers]u8 = [_]u8{0} ** registers; // create the register file
    pub var i: u16 = 0; // index register
    pub var stack: [stack_size]u16 = [_]u16{0} ** stack_size; // create a stack
    pub var sp: u8 = 0; // stack pointer
    pub var delay_timer: u8 = 0;
    pub var sound_timer: u8 = 0;
    pub var exit: bool = false; // exit flag
    pub var address16f: bool = false;

    pub var increment_i: bool = false; // due for different behaviors for different variations of chip8

    pub fn fetch() u16 {
        // get an instruction
        const upper = @as(u16, memory.memory.read(CPU.pc));
        const lower = @as(u16, memory.memory.read(CPU.pc + 1));
        CPU.pc += 2;
        return (upper << 8) | lower;
    }

    pub fn push(value: u16) void {
        // push onto the stack
        CPU.stack[CPU.sp] = value;
        CPU.sp += 1;
    }

    pub fn pop() u16 {
        // pop the stack
        CPU.sp -= 1;
        return CPU.stack[CPU.sp];
    }

    // save current flags to memory/
    pub fn save_flags(x: u4) void {
        const file = std.fs.cwd().createFile("flags.bin", .{}) catch return;
        defer file.close();
        file.writeAll(CPU.register[0 .. @as(usize, x) + 1]) catch return;
    }

    // load from binary
    pub fn load_flags(x: u4) void {
        const file = std.fs.cwd().openFile("flags.bin", .{}) catch return;
        defer file.close();
        _ = file.readAll(CPU.register[0 .. @as(usize, x) + 1]) catch return;
    }

    // get the size of the next instruction for various different variations of the Chip8 interperter
    fn next_inst_size() u16 {
        const hi = memory.memory.read(CPU.pc);
        const lo = memory.memory.read(CPU.pc + 1);
        return if (hi == 0xF0 and lo == 0x00) 4 else 2;
    }

    // execute commands
    pub fn execute(opcode: u16) void {
        if (CPU.address16f) {
            CPU.i = opcode;
            CPU.address16f = false;
            return;
        }

        // extract hex digits from the op code
        const a: u4 = @as(u4, @truncate(opcode >> 12));
        const b: u4 = @as(u4, @truncate(opcode >> 8));
        const c: u4 = @as(u4, @truncate(opcode >> 4));
        const d: u4 = @as(u4, @truncate(opcode));

        // organize instructions on instr type
        switch (a) {
            0x0 => {
                switch (c) {
                    0xC => display.display.shift_display_vertical(false, d),
                    0xD => display.display.shift_display_vertical(true, d),
                    0xE => {
                        switch (d) {
                            0x0 => display.display.clear_display(),
                            0xE => CPU.pc = CPU.pop(),
                            else => std.debug.print("{x}{x}{x}{x} not implemented\n", .{ a, b, c, d }),
                        }
                    },
                    0xF => {
                        switch (d) {
                            0xB => display.display.scroll_horizontal(true),
                            0xC => display.display.scroll_horizontal(false),
                            0xD => CPU.exit = true,
                            0xE => {
                                display.display.lowres = true;
                                display.display.clear_display();
                            },
                            0xF => {
                                display.display.lowres = false;
                                display.display.clear_display();
                            },
                            else => std.debug.print("{x}{x}{x}{x} not implemented\n", .{ a, b, c, d }),
                        }
                    },
                    else => std.debug.print("{x}{x}{x}{x} not implemented\n", .{ a, b, c, d }),
                }
            },
            0x1 => {
                CPU.pc = @as(u16, b) << 8 | @as(u16, c) << 4 | @as(u16, d);
            },
            0x2 => {
                const nnn: u16 = @as(u16, b) << 8 | @as(u16, c) << 4 | @as(u16, d);
                CPU.push(CPU.pc);
                CPU.pc = nnn;
            },
            0x3 => {
                if (CPU.register[b] == (@as(u8, c) << 4 | @as(u8, d))) {
                    CPU.pc += next_inst_size();
                }
            },
            0x4 => {
                if (CPU.register[b] != (@as(u8, c) << 4 | @as(u8, d))) {
                    CPU.pc += next_inst_size();
                }
            },
            0x5 => {
                switch (d) {
                    0x0 => {
                        if (CPU.register[b] == CPU.register[c]) {
                            CPU.pc += next_inst_size();
                        }
                    },
                    0x2 => {
                        for (@as(usize, b)..@as(usize, c) + 1) |val| {
                            memory.memory.write(CPU.i + @as(u16, @intCast(val - b)), CPU.register[val]);
                        }
                    },
                    0x3 => {
                        for (@as(usize, b)..@as(usize, c) + 1) |val| {
                            CPU.register[val] = memory.memory.read(CPU.i + @as(u16, @intCast(val - b)));
                        }
                    },
                    else => std.debug.print("{x}{x}{x}{x} not implemented\n", .{ a, b, c, d }),
                }
            },
            0x6 => {
                CPU.register[b] = @as(u8, c) << 4 | @as(u8, d);
            },
            0x7 => {
                CPU.register[b] +%= @as(u8, c) << 4 | @as(u8, d);
            },
            0x8 => {
                switch (d) {
                    0x0 => CPU.register[b] = CPU.register[c],
                    0x1 => {
                        CPU.register[b] |= CPU.register[c];
                        CPU.register[0xF] = 0;
                    },
                    0x2 => {
                        CPU.register[b] &= CPU.register[c];
                        CPU.register[0xF] = 0;
                    },
                    0x3 => {
                        CPU.register[b] ^= CPU.register[c];
                        CPU.register[0xF] = 0;
                    },
                    0x4 => {
                        const sum = @as(u9, CPU.register[b]) + @as(u9, CPU.register[c]);
                        const overflow: u8 = if (sum > 0xFF) 1 else 0;
                        CPU.register[b] = @truncate(sum);
                        CPU.register[0xF] = overflow;
                    },
                    0x5 => {
                        const difference = @as(u9, CPU.register[b]) -% @as(u9, CPU.register[c]);
                        const borrow: u8 = if (difference >> 8 != 0) 0 else 1;
                        CPU.register[b] = @truncate(difference);
                        CPU.register[0xF] = borrow;
                    },
                    0x6 => {
                        const lsb: u8 = CPU.register[b] & 1;
                        CPU.register[b] >>= 1;
                        CPU.register[0xF] = lsb;
                    },
                    0x7 => {
                        const difference = @as(u9, CPU.register[c]) -% @as(u9, CPU.register[b]);
                        const borrow: u8 = if (difference >> 8 != 0) 0 else 1;
                        CPU.register[b] = @truncate(difference);
                        CPU.register[0xF] = borrow;
                    },
                    0xE => {
                        const msb: u8 = (CPU.register[b] >> 7) & 1;
                        CPU.register[b] <<= 1;
                        CPU.register[0xF] = msb;
                    },
                    else => std.debug.print("{x}{x}{x}{x} not implemented\n", .{ a, b, c, d }),
                }
            },
            0x9 => {
                if (CPU.register[b] != CPU.register[c]) {
                    CPU.pc += next_inst_size();
                }
            },
            0xA => {
                CPU.i = @as(u16, b) << 8 | @as(u16, c) << 4 | @as(u16, d);
            },
            0xB => {
                const xnn: u16 = @as(u16, b) << 8 | @as(u16, c) << 4 | @as(u16, d);
                CPU.pc = xnn + CPU.register[0];
            },
            0xC => {
                const nn: u8 = @as(u8, c) << 4 | @as(u8, d);
                CPU.register[b] = std.crypto.random.int(u8) & nn;
            },
            0xD => {
                switch (d) {
                    0x0 => display.display.draw_large(CPU.register[b], CPU.register[c]),
                    else => display.display.draw_small(CPU.register[b], CPU.register[c], d),
                }
            },
            0xE => {
                const key = CPU.register[b] & 0xF;
                const is_pressed = input.input.keys[key];
                const nn: u8 = @as(u8, c) << 4 | @as(u8, d);
                if (nn == 0x9E and is_pressed) {
                    CPU.pc += next_inst_size();
                } else if (nn == 0xA1 and !is_pressed) {
                    CPU.pc += next_inst_size();
                }
            },
            0xF => {
                const nn: u8 = @as(u8, c) << 4 | @as(u8, d);
                if (b == 0x0 and nn == 0x00) {
                    CPU.address16f = true;
                } else if (b == 0x0 and nn == 0x02) {
                    for (0..16) |idx| {
                        audio.audio.audio_buffer[idx] = memory.memory.read(CPU.i + @as(u16, @intCast(idx)));
                    }
                } else {
                    switch (nn) {
                        0x01 => display.display.selected_plane = @truncate(b),
                        0x07 => CPU.register[b] = CPU.delay_timer,
                        0x0A => {
                            var found = false;
                            for (0..16) |k| {
                                if (input.input.last_keys[k] and !input.input.keys[k]) {
                                    CPU.register[b] = @truncate(k);
                                    input.input.last_keys[k] = false; // consume
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) CPU.pc -= 2;
                        },
                        0x15 => CPU.delay_timer = CPU.register[b],
                        0x18 => CPU.sound_timer = CPU.register[b],
                        0x1E => CPU.i +%= CPU.register[b],
                        0x29 => CPU.i = @as(u16, CPU.register[b] & 0xF) * 5,
                        0x30 => CPU.i = 80 + @as(u16, CPU.register[b] & 0xF) * 10,
                        0x33 => {
                            const val = CPU.register[b];
                            memory.memory.write(CPU.i, val / 100);
                            memory.memory.write(CPU.i + 1, (val / 10) % 10);
                            memory.memory.write(CPU.i + 2, val % 10);
                        },
                        0x3A => audio.audio.pitch = CPU.register[b],
                        0x55 => {
                            for (0..@as(usize, b) + 1) |idx| {
                                memory.memory.write(CPU.i + @as(u16, @intCast(idx)), CPU.register[idx]);
                            }
                            if (CPU.increment_i) CPU.i += @as(u16, b) + 1;
                        },
                        0x65 => {
                            for (0..@as(usize, b) + 1) |idx| {
                                CPU.register[idx] = memory.memory.read(CPU.i + @as(u16, @intCast(idx)));
                            }
                            if (CPU.increment_i) CPU.i += @as(u16, b) + 1;
                        },
                        0x75 => CPU.save_flags(if (b <= 7) b else 7),
                        0x85 => CPU.load_flags(if (b <= 7) b else 7),
                        else => std.debug.print("{x}{x}{x}{x} not implemented\n", .{ a, b, c, d }),
                    }
                }
            },
        }
    }
};
