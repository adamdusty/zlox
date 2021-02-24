const std = @import("std");
const code = @import("code.zig");
const value = @import("value.zig");
const debug = @import("debug.zig");


const Stack = @import("stack.zig").Stack;
const Allocator = std.mem.Allocator;
const Chunk = code.Chunk;
const OpCode = code.OpCode;
const Value = value.Value;

pub const InterpretResult = enum {
    Ok,
    CompileError,
    RuntimeError
};

pub const VirtualMachine = struct {
    chunk: ?*Chunk,
    instruction: *u8,
    callStack: Stack(Value),


    pub fn init(allocator: *Allocator) !VirtualMachine {
        var stack = try Stack(Value).init(allocator, 256);
        return VirtualMachine {
            .chunk = null,
            .instruction = undefined,
            .callStack = stack
        };
    }

    pub fn deinit(self: *VirtualMachine) void {

    }

    pub fn interpret(self: *VirtualMachine, c: *Chunk) InterpretResult {
        self.chunk = c;
        self.instruction = &self.chunk.?.code.items[0];
        return self.run();
    }

    pub fn run(self: *VirtualMachine) InterpretResult {
        while(true) {
            if(debug.TRACE_EXECUTION){
                std.debug.print("          ", .{});
                for(self.callStack.items) |val| {
                    std.debug.print("[ {d} ]", .{val});
                }
                std.debug.print("\n", .{});

                const debugInstruction = @ptrToInt(&self.chunk.?.code.items[self.instruction.*]) - @ptrToInt(self.chunk.?.code.items.ptr);
                _ = self.chunk.?.disassembleInstruction(debugInstruction);
            }
            const instruction = self.readByte();
            const opCode = @intToEnum(OpCode, instruction);

            switch (opCode){
                OpCode.Return => {
                    const val = self.callStack.pop();
                    std.debug.print("{d}", .{val});
                    return InterpretResult.Ok;
                },
                OpCode.Constant => {
                    const constant = self.readByte();
                    const val = self.chunk.?.constants.items[constant];
                    self.callStack.push(val);
                }
            }
        }
    }

    pub fn readByte(self: *VirtualMachine) u8 {
        const byte = self.chunk.?.code.items[self.instruction.*];
        self.instruction.* += 1;
        return byte;
    }

    // pub fn readConstant(self: *VirtualMachine) Value {

    // }
};