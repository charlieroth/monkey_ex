const std = @import("std");
const mem = std.mem;

pub const TokenType = enum {
    Illegal,
    Eof,
    // Identifiers
    ReadIdent,
    Ident,
    // Types
    Int,
    // Operators
    Assign,
    Plus,
    Minus,
    Bang,
    Asterisk,
    Slash,
    LessThan,
    GreaterThan,
    EqualEqual,
    NotEqual,
    // Syntax
    Comma,
    Semicolon,
    LParen,
    RParen,
    LBrace,
    RBrace,
    // Keywords
    Let,
    If,
    Else,
    Function,
    Return,
    True,
    False,
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
        return TokenType.Let;
    } else if (mem.eql(u8, keyword, "fn")) {
        return TokenType.Function;
    } else if (mem.eql(u8, keyword, "return")) {
        return TokenType.Return;
    } else if (mem.eql(u8, keyword, "if")) {
        return TokenType.If;
    } else if (mem.eql(u8, keyword, "else")) {
        return TokenType.Else;
    } else if (mem.eql(u8, keyword, "true")) {
        return TokenType.True;
    } else if (mem.eql(u8, keyword, "false")) {
        return TokenType.False;
    } else {
        return TokenType.Ident;
    }
}
