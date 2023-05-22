const std = @import("std");
const mem = std.mem;

pub const TokenType = enum {
    ReadIdent,
    Illegal,
    Eof,
    Ident,
    Int,
    Assign,
    Plus,
    Comma,
    Semicolon,
    LParen,
    RParen,
    LBrace,
    RBrace,
    Function,
    Let,
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

pub fn lookup_ident(ident: []const u8) TokenType {
    if (mem.eql(u8, ident, "fn")) {
        return TokenType.Function;
    } else if (mem.eql(u8, ident, "let")) {
        return TokenType.Let;
    } else {
        return TokenType.Ident;
    }
}
