const std = @import("std");
const repl = @import("repl.zig");

const mem = std.mem;
const heap = std.heap;
const fs = std.fs;
const io = std.io;
const debug = std.debug;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator: mem.Allocator = gpa.allocator();
    defer {
        const deinit_check = gpa.deinit();
        debug.assert(deinit_check == .ok);
    }

    const stdin: fs.File.Reader = io.getStdIn().reader();
    const stdout: fs.File.Writer = io.getStdOut().writer();
    try repl.start(allocator, stdin, stdout);
}
