const std = @import("std");
const code = @import("code.zig");
const value = @import("value.zig");
const debug = @import("debug.zig");
const compiler = @import("compiler.zig");

const Stack = @import("stack.zig").Stack;
const Allocator = std.mem.Allocator;
const Chunk = code.Chunk;
const OpCode = code.OpCode;
const Value = value.Value;

pub const InterpretResult = enum {
    Ok, CompileError, RuntimeError
};

pub const VirtualMachine = struct {
    chunk: ?*Chunk,
    instructionPointer: *u8,
    callStack: Stack(Value),
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) !VirtualMachine {
        var stack = try Stack(Value).init(allocator, 256);
        return VirtualMachine{
            .chunk = null,
            .instructionPointer = undefined,
            .callStack = stack,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *VirtualMachine) void {
        self.chunk.?.deinit();
        self.callStack.deinit();
    }

    pub fn interpret(self: *VirtualMachine, source: []const u8) InterpretResult {
        const chunk = Chunk.init(self.allocator);

        if (!compile(self, source, &chunk)) {
            chunk.deinit();
            return InterpretResult.CompileError;
        }

        self.chunk = &chunk;
        self.instructionPointer = &self.chunk.?.code.items[0];

        const result = self.run();

        chunk.deinit();

        return result;
    }

    pub fn run(self: *VirtualMachine) InterpretResult {
        while (true) {
            if (debug.TRACE_EXECUTION) {
                std.debug.print("{s:>10}", .{""});
                for (self.callStack.items) |val| {
                    std.debug.print("[ {d} ]", .{val});
                }
                std.debug.print("\n", .{});
                const debugInstruction = @ptrToInt(&self.chunk.?.code.items[self.instructionPointer.*]) - @ptrToInt(self.chunk.?.code.items.ptr);
                _ = self.chunk.?.disassembleInstruction(debugInstruction);
            }
            const instruction = self.readByte();
            const opCode = @intToEnum(OpCode, instruction);

            switch (opCode) {
                OpCode.Add => {
                    self.binaryOp(add);
                },
                OpCode.Subtract => {
                    self.binaryOp(sub);
                },
                OpCode.Multiply => {
                    self.binaryOp(mul);
                },
                OpCode.Divide => {
                    self.binaryOp(div);
                },
                OpCode.Negate => {
                    self.callStack.push(-self.callStack.pop());
                },
                OpCode.Return => {
                    const val = self.callStack.pop();
                    std.debug.print("{d}", .{val});
                    return InterpretResult.Ok;
                },
                OpCode.Constant => {
                    // Read the byte directly after the constant OpCode
                    // The byte is the index to the constant array that holds the actual value
                    const constant = self.readByte();
                    const val = self.chunk.?.constants.items[constant];
                    self.callStack.push(val);
                },
            }
        }
    }

    pub fn readByte(self: *VirtualMachine) u8 {
        const byte = self.chunk.?.code.items[self.instructionPointer.*];
        self.instructionPointer.* += 1;
        return byte;
    }

    pub fn binaryOp(self: *VirtualMachine, comptime op: anytype) void {
        const rhs = self.callStack.pop();
        const lhs = self.callStack.pop();
        self.callStack.push(op(lhs, rhs));
    }
};

fn add(lhs: Value, rhs: Value) Value {
    return lhs + rhs;
}

fn sub(lhs: Value, rhs: Value) Value {
    return lhs - rhs;
}

fn mul(lhs: Value, rhs: Value) Value {
    return lhs * rhs;
}

fn div(lhs: Value, rhs: Value) Value {
    return lhs / rhs;
}
