const std = @import("std");
const scanner = @import("scanner.zig");
const virtualMachine = @import("vm.zig");
const code = @import("code.zig");

const Chunk = code.Chunk;
const Scanner = scanner.Scanner;
const Token = scanner.Token;
const TokenType = scanner.TokenType;
const VirtualMachine = virtualMachine.VirtualMachine;

pub fn compile(vm: *VirtualMachine, source: []const u8, chunk: *Chunk) void {
    var comp = Compiler.init(vm);
    defer comp.deinit();

    var scan = Scanner.init(source);
    defer scan.deinit();

    comp.advance();
    comp.expression();
    comp.consume(TokenType.EOF, "Expect end of expression.");
}

const Compiler = struct {
    vm: *VirtualMachine,

    pub fn init(vm: *VirtualMachine) Compiler {
        return Compiler{ .vm = vm };
    }

    pub fn deinit() void {}

    pub fn advance() void {}
};
