const std = @import("std");
const code = @import("code.zig");
const vm = @import("vm.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};


pub fn main() anyerror!void {
    var executor = try vm.VirtualMachine.init(&gpa.allocator);
    defer executor.deinit();

    var c = code.Chunk.init(&gpa.allocator);
    defer c.deinit();

    const x = try c.addConstant(1.2);
    try c.writeOp(code.OpCode.Constant, 123);
    try c.write(x, 123);
    try c.writeOp(code.OpCode.Return, 125);
    
    const r = executor.interpret(&c);
}
