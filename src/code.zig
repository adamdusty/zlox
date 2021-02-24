const std = @import("std");
const Value = @import("value.zig").Value;
const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};


pub const OpCode = enum(u8) {
    Constant,
    Return
};

pub const Chunk = struct {
    code: std.ArrayList(u8),
    constants: std.ArrayList(Value),
    lines: std.ArrayList(usize),

    pub fn init(allocator: *Allocator) Chunk {
        return Chunk {
            .code = std.ArrayList(u8).init(allocator),
            .constants = std.ArrayList(Value).init(allocator),
            .lines = std.ArrayList(usize).init(allocator)
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }

    pub fn write(self: *Chunk, byte: u8, line: usize) !void {
        try self.code.append(byte);
        try self.lines.append(line);
    }

    pub fn writeOp(self: *Chunk, byte: OpCode, line: usize) !void {
        try self.code.append(@enumToInt(byte));
        try self.lines.append(line);
    }

    pub fn addConstant(self: *Chunk, value: Value) !u8 {
        const index = @intCast(u8, self.constants.items.len);
        try self.constants.append(value);
        return index;
    }

    pub fn disassemble(self: *Chunk, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});

        var offset: usize = 0;
        while(offset < self.code.items.len) {
            offset = self.disassembleInstruction(offset);
        }
    }

    pub fn disassembleInstruction(self: *Chunk, offset: usize) usize {
        std.debug.print("{:0>4} ", .{offset});

        if(offset > 0 and self.lines.items[offset] == self.lines.items[offset - 1]) {
            std.debug.print("   | ", .{});
        } else {
            std.debug.print("{d:4} ", .{self.lines.items[offset]});
        }
        const instruction = @intToEnum(OpCode, self.code.items[offset]);

        switch(instruction) {
            OpCode.Constant => return constantInstruction("OP_CONSTANT", self, offset),
            OpCode.Return => return simpleInstruction("OP_RETURN", offset)
        }
    }


};

fn simpleInstruction(name: []const u8, offset: usize) usize {
    std.debug.print("{s} ", .{name});
    return offset + 1;
}

fn constantInstruction(name: []const u8, c: *Chunk, offset: usize) usize {
    const constant = c.code.items[offset + 1];
    std.debug.print("{s:<16} {d:4}'{d}'\n", .{name, constant, c.constants.items[constant]});
    return offset + 2;
}