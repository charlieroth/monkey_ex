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
                    tok = Token.init(.equal_equal, "==");
                } else {
                    tok = Token.init(.assign, "=");
                }
            },
            '+' => {
                tok = Token.init(.plus, "+");
            },
            '(' => {
                tok = Token.init(.l_paren, "(");
            },
            ')' => {
                tok = Token.init(.r_paren, ")");
            },
            '{' => {
                tok = Token.init(.l_brace, "{");
            },
            '}' => {
                tok = Token.init(.r_brace, "}");
            },
            ',' => {
                tok = Token.init(.comma, ",");
            },
            ';' => {
                tok = Token.init(.semicolon, ";");
            },
            '-' => {
                tok = Token.init(.minus, "-");
            },
            '!' => {
                if (self.peek_char() == '=') {
                    self.read_char();
                    tok = Token.init(.not_equal, "!=");
                } else {
                    tok = Token.init(.bang, "!");
                }
            },
            '*' => {
                tok = Token.init(.asterisk, "*");
            },
            '/' => {
                tok = Token.init(.slash, "/");
            },
            '<' => {
                tok = Token.init(.less_than, "<");
            },
            '>' => {
                tok = Token.init(.greater_than, ">");
            },
            0 => {
                tok = Token.init(.eof, "");
            },
            else => {
                if (token.is_letter(self.ch)) {
                    tok = Token{ .t = undefined, .literal = undefined };
                    tok.literal = self.read_identifier();
                    tok.t = token.lookup_keywords(tok.literal);
                    return tok;
                } else if (token.is_digit(self.ch)) {
                    return Token.init(.int, self.read_number());
                } else {
                    tok = Token.init(.illegal, "");
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
