const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const TokenType = @import("token.zig").TokenType;

const fs = std.fs;
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;

const PROMPT = ">> ";

pub fn start(allocator: mem.Allocator, stdin: fs.File.Reader, stdout: fs.File.Writer) !void {
    while (true) {
        _ = try stdout.write(PROMPT);
        const input = try stdin.readUntilDelimiterAlloc(allocator, '\n', 1000);
        var lexer = Lexer.init(allocator, input);

        // TODO(charlieroth): Might be a MacOS/iTerm thing but there seems to
        // always be an "illegal" character, (170) at the start of the input
        // string so consume an extra token to avoid this. Look into this
        // if it causes any issues. Might need to run repl with "raw" mode.
        // After implementation is complete might be good to integrate
        // https://github.com/joachimschmidt557/linenoize into the project/repl.
        var tok = lexer.next_token();
        tok = lexer.next_token();
        while (tok.t != TokenType.eof) : (tok = lexer.next_token()) {
            debug.print("[{any}]::[{s}]\n", .{ tok.t, tok.literal });
        }
    }
}
