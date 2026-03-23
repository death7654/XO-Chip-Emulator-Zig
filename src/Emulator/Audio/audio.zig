const std = @import("std");
const sdl = @cImport(@cInclude("SDL2/SDL.h"));

pub const audio = struct {
    pub var audio_buffer: [16]u8 = [_]u8{0} ** 16;
    pub var pitch: u8 = 64;
    pub var device: sdl.SDL_AudioDeviceID = 0;

    var bit_position: usize = 0;
    var sample_counter: f64 = 0.0;

    fn audioCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
        _ = userdata;
        const pitch_f: f64 = @floatFromInt(audio.pitch);
        const bit_rate: f64 = 4000.0 * std.math.pow(f64, 2.0, (pitch_f - 64.0) / 48.0);
        const samples_per_bit: f64 = 44100.0 / bit_rate;

        const length: usize = @intCast(len);
        var i: usize = 0;
        while (i < length) : (i += 1) {
            const byte_idx = bit_position / 8;
            const bit_idx: u3 = @intCast(7 - (bit_position % 8));
            const bit = (audio.audio_buffer[byte_idx] >> bit_idx) & 1;

            // AUDIO_U8: silence = 128; high and low are symmetric around it
            stream[i] = if (bit != 0) 200 else 56;

            sample_counter += 1.0;
            if (sample_counter >= samples_per_bit) {
                sample_counter -= samples_per_bit;
                bit_position = (bit_position + 1) % 128;
            }
        }
    }

    pub fn init() void {
        // init sdl subsystem
        if (sdl.SDL_InitSubSystem(sdl.SDL_INIT_AUDIO) < 0) {
            std.debug.print("SDL_InitSubSystem(AUDIO) failed: {s}\n", .{sdl.SDL_GetError()});
            return;
        }

        var desired = std.mem.zeroes(sdl.SDL_AudioSpec);
        desired.freq = 44100;
        desired.format = sdl.AUDIO_U8;
        desired.channels = 1;
        desired.samples = 512;
        desired.callback = audioCallback;

        var obtained: sdl.SDL_AudioSpec = undefined;
        audio.device = sdl.SDL_OpenAudioDevice(null, 0, &desired, &obtained, 0);
        if (audio.device == 0) {
            std.debug.print("SDL_OpenAudioDevice failed: {s}\n", .{sdl.SDL_GetError()});
        }
        // Start paused; update() unpauses when sound_timer > 0
        sdl.SDL_PauseAudioDevice(audio.device, 1);
    }

    // destroy audo subsystem
    pub fn deinit() void {
        if (audio.device != 0) sdl.SDL_CloseAudioDevice(audio.device);
    }

    /// Call once per frame after decrementing sound_timer.
    pub fn update(sound_timer: u8) void {
        if (audio.device == 0) return;
        sdl.SDL_PauseAudioDevice(audio.device, if (sound_timer > 0) 0 else 1);
    }
};
