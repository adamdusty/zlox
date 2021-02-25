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

    switch (args.len) {
        1 => try repl(&executor),
        2 => try runfile(args[1], &executor),
        else => {
            std.debug.print("Usage: clox path\n", .{});
            std.process.exit(64);
        },
    }
}

fn repl(exec: *vm.VirtualMachine) !void {
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn();

    var buffer: [256]u8 = undefined;

    while (true) {
        try stderr.print("> ", .{});
        const inputSize = try stdin.read(&buffer);
        const source = buffer[0..inputSize];
        const interpretResult = exec.interpret(source);
    }
}

fn runfile(path: []const u8, exec: *vm.VirtualMachine) !void {
    const source = try readfile(path);
    const result = exec.interpret(source);

    switch (result) {
        InterpretResult.CompileError => std.process.exit(65),
        InterpretResult.RuntimeError => std.process.exit(70),
        InterpretResult.Ok => {},
    }
}

fn readfile(path: []const u8) ![]const u8 {
    var file = try std.fs.openFileAbsolute(path, .{ .read = true });
    const fileStats = try file.stat();
    const result = try gpa.allocator.alloc(u8, fileStats.size);
    errdefer gpa.allocator.free(result);

    const read_result = try file.read(result);
    return result;
}

fn interpret(source: []const u8) InterpretResult {
    return InterpretResult.CompileError;
}
