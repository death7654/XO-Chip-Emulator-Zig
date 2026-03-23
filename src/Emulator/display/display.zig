const memory = @import("../memory/memory.zig");
const cpu = @import("../CPU/cpu.zig");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const width: usize = 128;
const height: usize = 64;
const total: usize = height * width;
const scale: c_int = 10;

pub const display = struct {
    pub var plane1: [total]u1 = [_]u1{0} ** total;
    pub var plane2: [total]u1 = [_]u1{0} ** total;
    pub var lowres: bool = true;
    pub var selected_plane: u2 = 1;
    pub var window: ?*sdl.SDL_Window = null;
    pub var renderer: ?*sdl.SDL_Renderer = null;

    pub fn init() void {
        _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
        display.window = sdl.SDL_CreateWindow(
            "XO-CHIP",
            sdl.SDL_WINDOWPOS_CENTERED,
            sdl.SDL_WINDOWPOS_CENTERED,
            @as(c_int, @intCast(width)) * scale,
            @as(c_int, @intCast(height)) * scale,
            0,
        );
        display.renderer = sdl.SDL_CreateRenderer(display.window, -1, sdl.SDL_RENDERER_PRESENTVSYNC);
    }

    pub fn deinit() void {
        sdl.SDL_DestroyRenderer(display.renderer);
        sdl.SDL_DestroyWindow(display.window);
        sdl.SDL_Quit();
    }

    pub fn render() void {
        // background clear
        _ = sdl.SDL_SetRenderDrawColor(display.renderer, 0, 0, 0, 255);
        _ = sdl.SDL_RenderClear(display.renderer);

        const screen_w: usize = if (display.lowres) width / 2 else width;
        const screen_h: usize = if (display.lowres) height / 2 else height;

        var win_w: c_int = 0;
        var win_h: c_int = 0;
        sdl.SDL_GetWindowSize(display.window, &win_w, &win_h);

        const cell_w = @divTrunc(win_w, @as(c_int, @intCast(screen_w)));
        const cell_h = @divTrunc(win_h, @as(c_int, @intCast(screen_h)));

        var y: usize = 0;
        while (y < screen_h) : (y += 1) {
            var x: usize = 0;
            while (x < screen_w) : (x += 1) {
                // sample from physical buffer — in lores each logical pixel is 2x2
                const idx = if (display.lowres)
                    (y * 2) * width + (x * 2)
                else
                    y * width + x;

                const bp0: bool = display.plane1[idx] != 0 and (display.selected_plane & 1) != 0;
                const bp1: bool = display.plane2[idx] != 0 and (display.selected_plane & 2) != 0;

                if (!bp0 and !bp1) continue;

                // match C setColor logic
                if (bp0 and bp1) {
                    _ = sdl.SDL_SetRenderDrawColor(display.renderer, 100, 100, 100, 255);
                } else if (bp0) {
                    _ = sdl.SDL_SetRenderDrawColor(display.renderer, 255, 255, 255, 255);
                } else {
                    _ = sdl.SDL_SetRenderDrawColor(display.renderer, 255, 100, 100, 255);
                }

                const rect = sdl.SDL_Rect{
                    .x = @as(c_int, @intCast(x)) * cell_w,
                    .y = @as(c_int, @intCast(y)) * cell_h,
                    .w = cell_w,
                    .h = cell_h,
                };
                _ = sdl.SDL_RenderFillRect(display.renderer, &rect);
            }
        }
        sdl.SDL_RenderPresent(display.renderer);
    }

    pub fn shift_display_vertical(up: bool, n: u4) void {
        const rows: usize = if (display.lowres) @as(usize, n) / 2 else @as(usize, n);
        const offset = rows * width;

        if (up) {
            var i: usize = 0;
            while (i < total - offset) : (i += 1) {
                if (display.selected_plane & 1 != 0) display.plane1[i] = display.plane1[i + offset];
                if (display.selected_plane & 2 != 0) display.plane2[i] = display.plane2[i + offset];
            }
            i = total - offset;
            while (i < total) : (i += 1) {
                if (display.selected_plane & 1 != 0) display.plane1[i] = 0;
                if (display.selected_plane & 2 != 0) display.plane2[i] = 0;
            }
        } else {
            var i: usize = total;
            while (i > offset) {
                i -= 1;
                if (display.selected_plane & 1 != 0) display.plane1[i] = display.plane1[i - offset];
                if (display.selected_plane & 2 != 0) display.plane2[i] = display.plane2[i - offset];
            }
            i = 0;
            while (i < offset) : (i += 1) {
                if (display.selected_plane & 1 != 0) display.plane1[i] = 0;
                if (display.selected_plane & 2 != 0) display.plane2[i] = 0;
            }
        }
    }

    pub fn scroll_horizontal(right: bool) void {
        const cols: usize = if (display.lowres) 2 else 4;
        var row: usize = 0;
        while (row < height) : (row += 1) {
            const row_start = row * width;
            if (right) {
                var col: usize = width - 1;
                while (col >= cols) {
                    col -= 1;
                    if (display.selected_plane & 1 != 0) display.plane1[row_start + col + cols] = display.plane1[row_start + col];
                    if (display.selected_plane & 2 != 0) display.plane2[row_start + col + cols] = display.plane2[row_start + col];
                }
                var i: usize = 0;
                while (i < cols) : (i += 1) {
                    if (display.selected_plane & 1 != 0) display.plane1[row_start + i] = 0;
                    if (display.selected_plane & 2 != 0) display.plane2[row_start + i] = 0;
                }
            } else {
                var col: usize = 0;
                while (col < width - cols) : (col += 1) {
                    if (display.selected_plane & 1 != 0) display.plane1[row_start + col] = display.plane1[row_start + col + cols];
                    if (display.selected_plane & 2 != 0) display.plane2[row_start + col] = display.plane2[row_start + col + cols];
                }
                var i: usize = width - cols;
                while (i < width) : (i += 1) {
                    if (display.selected_plane & 1 != 0) display.plane1[row_start + i] = 0;
                    if (display.selected_plane & 2 != 0) display.plane2[row_start + i] = 0;
                }
            }
        }
    }

    pub fn clear_display() void {
        for (0..total) |i| {
            if (display.selected_plane & 1 != 0) display.plane1[i] = 0;
            if (display.selected_plane & 2 != 0) display.plane2[i] = 0;
        }
    }

    fn draw_pixel(plane: u2, px: usize, py: usize, collision: *u8) void {
        const lores_scale: usize = if (display.lowres) 2 else 1;
        var dy: usize = 0;
        while (dy < lores_scale) : (dy += 1) {
            var dx: usize = 0;
            while (dx < lores_scale) : (dx += 1) {
                const fx = px + dx;
                const fy = py + dy;
                if (fx >= width or fy >= height) continue;
                const idx = fy * width + fx;
                if (plane == 1) {
                    if (display.plane1[idx] == 1) collision.* = 1;
                    display.plane1[idx] ^= 1;
                } else {
                    if (display.plane2[idx] == 1) collision.* = 1;
                    display.plane2[idx] ^= 1;
                }
            }
        }
    }

    pub fn draw_large(x: u8, y: u8) void {
        var collision: u8 = 0;
        var mem_offset: u16 = 0;
        const lores_scale: usize = if (display.lowres) 2 else 1;
        const lores_width = width / lores_scale;
        const lores_height = height / lores_scale;

        var plane: u2 = 1;
        while (plane <= 2) : (plane += 1) {
            if (display.selected_plane & plane == 0) continue;

            var row: usize = 0;
            while (row < 16) : (row += 1) {
                const byte1 = memory.memory.read(cpu.CPU.i + mem_offset + @as(u16, @intCast(row * 2)));
                const byte2 = memory.memory.read(cpu.CPU.i + mem_offset + @as(u16, @intCast(row * 2 + 1)));

                const logical_y = (@as(usize, y) + row) % lores_height;
                const py = logical_y * lores_scale;

                var col: usize = 0;
                while (col < 16) : (col += 1) {
                    const bit: u1 = if (col < 8)
                        @truncate((byte1 >> @intCast(7 - col)) & 1)
                    else
                        @truncate((byte2 >> @intCast(15 - col)) & 1);

                    if (bit == 0) continue;

                    const logical_x = (@as(usize, x) + col) % lores_width;
                    const px = logical_x * lores_scale;
                    draw_pixel(plane, px, py, &collision);
                }
            }
            mem_offset += 32;
        }
        cpu.CPU.register[0xF] = collision;
    }

    pub fn draw_small(x: u8, y: u8, n: u4) void {
        var collision: u8 = 0;
        var mem_offset: u16 = 0;
        const lores_scale: usize = if (display.lowres) 2 else 1;
        const lores_width = width / lores_scale;
        const lores_height = height / lores_scale;

        var plane: u2 = 1;
        while (plane <= 2) : (plane += 1) {
            if (display.selected_plane & plane == 0) continue;

            var row: usize = 0;
            while (row < n) : (row += 1) {
                const byte = memory.memory.read(cpu.CPU.i + mem_offset + @as(u16, @intCast(row)));

                const logical_y = (@as(usize, y) + row) % lores_height;
                const py = logical_y * lores_scale;

                var col: usize = 0;
                while (col < 8) : (col += 1) {
                    const bit: u1 = @truncate((byte >> @intCast(7 - col)) & 1);
                    if (bit == 0) continue;

                    const logical_x = (@as(usize, x) + col) % lores_width;
                    const px = logical_x * lores_scale;
                    draw_pixel(plane, px, py, &collision);
                }
            }
            mem_offset += n;
        }
        cpu.CPU.register[0xF] = collision;
    }
};
