const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const token = @import("token.zig");
const Token = token.Token;
const TokenType = token.TokenType;

pub const Lexer = struct {
    allocator: mem.Allocator,
    input: []const u8,
    position: u32, // current position in input (points to current char)
    read_position: u32, // current reading position (after current char)
    ch: u8, // current char under examination

    pub fn init(allocator: mem.Allocator, input: []const u8) Lexer {
        return Lexer{
            .allocator = allocator,
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = undefined,
        };
    }

    pub fn read_char(self: *Lexer) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
    }

    pub fn next_token(self: *Lexer) Token {
        const tok: Token = switch (self.ch) {
            '=' => Token.init(TokenType.Assign, "="),
            '+' => Token.init(TokenType.Plus, "+"),
            '(' => Token.init(TokenType.LParen, "("),
            ')' => Token.init(TokenType.RParen, ")"),
            '{' => Token.init(TokenType.LBrace, "{"),
            '}' => Token.init(TokenType.RBrace, "}"),
            ',' => Token.init(TokenType.Comma, ","),
            ';' => Token.init(TokenType.Semicolon, ";"),
            0 => Token.init(TokenType.Eof, ""),
            else => {
                if (token.is_letter(self.ch)) {
                    var tok = Token{ .t = undefined, .literal = undefined };
                    tok.literal = self.read_identifier();
                    tok.t = token.lookup_ident(tok.literal);
                    return tok;
                }
                return Token.init(TokenType.Illegal, "");
            },
        };
        return tok;
    }

    pub fn read_identifier(self: *Lexer) []const u8 {
        var position = self.position;
        while (token.is_letter(self.ch)) {
            self.read_char();
        }
        return self.input[position..self.position];
    }
};

test "lexer: simple input" {
    const expected = [_]Token{
        Token.init(TokenType.Assign, "="),
        Token.init(TokenType.Plus, "+"),
        Token.init(TokenType.LParen, "("),
        Token.init(TokenType.RParen, ")"),
        Token.init(TokenType.LBrace, "{"),
        Token.init(TokenType.RBrace, "}"),
        Token.init(TokenType.Comma, ","),
        Token.init(TokenType.Semicolon, ";"),
    };
    const input = "=+(){},;";
    var lexer = Lexer.init(testing.allocator, input);
    lexer.read_char();
    for (expected) |expected_token| {
        const tok = lexer.next_token();
        try testing.expect(tok.t == expected_token.t);
        try testing.expect(mem.eql(u8, tok.literal, expected_token.literal));
    }
}

test "lexer: simple program" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\let result = add(five, ten);
    ;
    const expected = [_]Token{
        // let five = 5;
        Token.init(TokenType.Let, "let"),
        Token.init(TokenType.Ident, "five"),
        Token.init(TokenType.Assign, "="),
        Token.init(TokenType.Int, "5"),
        Token.init(TokenType.Semicolon, ";"),
        // let ten = 10;
        Token.init(TokenType.Let, "let"),
        Token.init(TokenType.Ident, "ten"),
        Token.init(TokenType.Assign, "="),
        Token.init(TokenType.Int, "10"),
        Token.init(TokenType.Semicolon, ";"),
        // let add = fn(x, y) { x + y; };
        Token.init(TokenType.Let, "let"),
        Token.init(TokenType.Ident, "add"),
        Token.init(TokenType.Assign, "="),
        Token.init(TokenType.Function, "fn"),
        Token.init(TokenType.LParen, "("),
        Token.init(TokenType.Ident, "x"),
        Token.init(TokenType.Comma, ","),
        Token.init(TokenType.Ident, "y"),
        Token.init(TokenType.RParen, ")"),
        Token.init(TokenType.LBrace, "{"),
        Token.init(TokenType.Ident, "x"),
        Token.init(TokenType.Plus, "+"),
        Token.init(TokenType.Ident, "y"),
        Token.init(TokenType.Semicolon, ";"),
        // let result = add(five, ten);
        Token.init(TokenType.Let, "let"),
        Token.init(TokenType.Ident, "result"),
        Token.init(TokenType.Assign, "="),
        Token.init(TokenType.Ident, "add"),
        Token.init(TokenType.LParen, "("),
        Token.init(TokenType.Ident, "five"),
        Token.init(TokenType.Comma, ","),
        Token.init(TokenType.Ident, "ten"),
        Token.init(TokenType.RParen, ")"),
        Token.init(TokenType.Semicolon, ";"),
        Token.init(TokenType.Eof, ""),
    };
    var lexer = Lexer.init(testing.allocator, input);
    lexer.read_char();
    for (expected) |expected_token| {
        const tok = lexer.next_token();
        try testing.expect(tok.t == expected_token.t);
        try testing.expect(mem.eql(u8, tok.literal, expected_token.literal));
    }
}
