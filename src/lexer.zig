const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;

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
        var tok: Token = undefined;
        self.skip_whitespace();
        switch (self.ch) {
            '=' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = Token.init(TokenType.EqualEqual, "==");
                } else {
                    tok = Token.init(TokenType.Assign, "=");
                }
            },
            '+' => {
                tok = Token.init(TokenType.Plus, "+");
            },
            '(' => {
                tok = Token.init(TokenType.LParen, "(");
            },
            ')' => {
                tok = Token.init(TokenType.RParen, ")");
            },
            '{' => {
                tok = Token.init(TokenType.LBrace, "{");
            },
            '}' => {
                tok = Token.init(TokenType.RBrace, "}");
            },
            ',' => {
                tok = Token.init(TokenType.Comma, ",");
            },
            ';' => {
                tok = Token.init(TokenType.Semicolon, ";");
            },
            '-' => {
                tok = Token.init(TokenType.Minus, "-");
            },
            '!' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = Token.init(TokenType.NotEqual, "!=");
                } else {
                    tok = Token.init(TokenType.Bang, "!");
                }
            },
            '*' => {
                tok = Token.init(TokenType.Asterisk, "*");
            },
            '/' => {
                tok = Token.init(TokenType.Slash, "/");
            },
            '<' => {
                tok = Token.init(TokenType.LessThan, "<");
            },
            '>' => {
                tok = Token.init(TokenType.GreaterThan, ">");
            },
            0 => {
                tok = Token.init(TokenType.Eof, "");
            },
            else => {
                if (token.is_letter(self.ch)) {
                    tok = Token{ .t = undefined, .literal = undefined };
                    tok.literal = self.read_identifier();
                    tok.t = token.lookup_keywords(tok.literal);
                    return tok;
                } else if (token.is_digit(self.ch)) {
                    return Token.init(TokenType.Int, self.read_number());
                } else {
                    tok = Token.init(TokenType.Illegal, "");
                }
            },
        }
        self.read_char();
        return tok;
    }

    pub fn peek_char(self: *Lexer) u8 {
        if (self.read_position >= self.input.len) {
            return 0;
        } else {
            return self.input[self.read_position];
        }
    }

    pub fn read_identifier(self: *Lexer) []const u8 {
        var position = self.position;
        while (token.is_letter(self.ch)) {
            self.read_char();
        }
        return self.input[position..self.position];
    }

    pub fn read_number(self: *Lexer) []const u8 {
        var position = self.position;
        while (token.is_digit(self.ch)) {
            self.read_char();
        }
        return self.input[position..self.position];
    }

    pub fn skip_whitespace(self: *Lexer) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
            self.read_char();
        }
    }
};
