const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn Stack(comptime T: type) type {
    return struct {
        pub const Self = Stack(T);

        buffer: []T,
        items: []T,
        allocator: *Allocator,

        pub fn init(allocator: *Allocator, capacity: usize) !Self {
            var buffer = try allocator.alloc(T, capacity);

            return Self{
                .buffer = buffer,
                .items = buffer[0..0],
                .allocator = allocator
            };
        }

        pub fn deinit(self: *Self)void {
            self.allocator.free(self.buffer);
        }

        pub fn push(self: *Self, item: T) void {
            assert(self.items.len < self.buffer.len);

            self.items = self.buffer[0 .. self.items.len + 1];
            self.items[self.items.len - 1] = item;
        }

        pub fn pop(self: *Self) T {
            const val = self.items[self.items.len - 1];
            self.items = self.buffer[0 .. self.items.len - 1];
            return val;
        }

        pub fn resize(self: *Self, len: usize) !void {
            assert(len <= self.buffer.len);

            self.items = self.buffer[0..len];
        }

    };
}