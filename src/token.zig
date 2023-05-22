const std = @import("std");
const mem = std.mem;

pub const TokenType = enum {
    illegal,
    eof,
    // Identifiers
    read_ident,
    ident,
    // Types
    int,
    // Operators
    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,
    less_than,
    greater_than,
    equal_equal,
    not_equal,
    // Syntax
    comma,
    semicolon,
    l_paren,
    r_paren,
    l_brace,
    r_brace,
    // Keywords
    let,
    _if,
    _else,
    function,
    _return,
    _true,
    _false,
};

pub const Token = struct {
    t: TokenType,
    literal: []const u8,

    pub fn init(t: TokenType, literal: []const u8) Token {
        return Token{
            .t = t,
            .literal = literal,
        };
    }
};

pub fn is_letter(ch: u8) bool {
    return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ch == '_';
}

pub fn is_digit(ch: u8) bool {
    return '0' <= ch and ch <= '9';
}

pub fn lookup_keywords(keyword: []const u8) TokenType {
    if (mem.eql(u8, keyword, "let")) {
        return .let;
    } else if (mem.eql(u8, keyword, "fn")) {
        return .function;
    } else if (mem.eql(u8, keyword, "return")) {
        return ._return;
    } else if (mem.eql(u8, keyword, "if")) {
        return ._if;
    } else if (mem.eql(u8, keyword, "else")) {
        return ._else;
    } else if (mem.eql(u8, keyword, "true")) {
        return ._true;
    } else if (mem.eql(u8, keyword, "false")) {
        return ._false;
    } else {
        return .ident;
    }
}
