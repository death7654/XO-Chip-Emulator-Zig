const size: usize = 0x10000;

pub const memory = struct {
    pub var ram: [size]u8 = [_]u8{0} ** size;
    pub fn read(address: u16) u8 {
        return memory.ram[address];
    }

    pub fn write(address: u16, value: u8) void {
        memory.ram[address] = value;
    }
};
