const std = @import("std");
const code = @import("code.zig");
const vm = @import("vm.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const InterpretResult = vm.InterpretResult;


pub fn main() anyerror!void {
    var executor = try vm.VirtualMachine.init(&gpa.allocator);
    defer executor.deinit();

    var c = code.Chunk.init(&gpa.allocator);
    defer c.deinit();

    const args = try std.process.argsAlloc(&gpa.allocator);
    defer std.process.argsFree(&gpa.allocator, args);

    switch(args.len){
        1 => try repl(),
        2 => runfile(args[1]),
        else => {
            std.debug.print("Usage: clox path\n", .{});
            std.process.exit(64);
        }
    }

}

fn repl() !void {
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn();

    var buffer: [256]u8 = undefined;

    while(true) {
        try stderr.print("> ", .{});
        const inputSize = try stdin.read(&buffer);
        const source = buffer[0..inputSize];
        interpret(source);
    }
}

fn runfile(path: []const u8) void {
    const source = readfile(path);
    const result = interpret(source);

    switch(result) {
        InterpretResult.CompileError => std.process.exit(65),
        InterpretResult.RuntimeError => std.process.exit(70),
        InterpretResult.Ok => {}
    }
}

fn readfile(path: []const u8) []const u8 {

}

fn interpret(source: []const u8) InterpretResult {

}