const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;

const token = @import("token.zig");
const Token = token.Token;
const TokenType = token.TokenType;

const Lexer = @import("lexer.zig").Lexer;

test "lexer: simple input" {
    const input = "=+(){},;";
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
    var lexer = Lexer.init(testing.allocator, input);
    lexer.read_char();
    for (expected) |expected_token| {
        const tok = lexer.next_token();
        // debug.print("atok: {any}\netok: {any}\n\n", .{ tok, expected_token });
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
        Token.init(TokenType.RBrace, "}"),
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
        // debug.print("atok: {any}\netok: {any}\n\n", .{ tok, expected_token });
        try testing.expect(tok.t == expected_token.t);
        try testing.expect(mem.eql(u8, tok.literal, expected_token.literal));
    }
}

test "lexer: simple program, operators & booleans" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
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
        Token.init(TokenType.RBrace, "}"),
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
        // !-/*5;
        Token.init(TokenType.Bang, "!"),
        Token.init(TokenType.Minus, "-"),
        Token.init(TokenType.Slash, "/"),
        Token.init(TokenType.Asterisk, "*"),
        Token.init(TokenType.Int, "5"),
        Token.init(TokenType.Semicolon, ";"),
        // 5 < 10 > 5;
        Token.init(TokenType.Int, "5"),
        Token.init(TokenType.LessThan, "<"),
        Token.init(TokenType.Int, "10"),
        Token.init(TokenType.GreaterThan, ">"),
        Token.init(TokenType.Int, "5"),
        Token.init(TokenType.Semicolon, ";"),
        //if (5 < 10) {
        //  return true;
        //} else {
        //  return false;
        //}
        Token.init(TokenType.If, "if"),
        Token.init(TokenType.LParen, "("),
        Token.init(TokenType.Int, "5"),
        Token.init(TokenType.LessThan, "<"),
        Token.init(TokenType.Int, "10"),
        Token.init(TokenType.RParen, ")"),
        Token.init(TokenType.LBrace, "{"),
        Token.init(TokenType.Return, "return"),
        Token.init(TokenType.True, "true"),
        Token.init(TokenType.Semicolon, ";"),
        Token.init(TokenType.RBrace, "}"),
        Token.init(TokenType.Else, "else"),
        Token.init(TokenType.LBrace, "{"),
        Token.init(TokenType.Return, "return"),
        Token.init(TokenType.False, "false"),
        Token.init(TokenType.Semicolon, ";"),
        Token.init(TokenType.RBrace, "}"),
        //10 == 10;
        //10 != 9;
        Token.init(TokenType.Int, "10"),
        Token.init(TokenType.EqualEqual, "=="),
        Token.init(TokenType.Int, "10"),
        Token.init(TokenType.Semicolon, ";"),
        Token.init(TokenType.Int, "10"),
        Token.init(TokenType.NotEqual, "!="),
        Token.init(TokenType.Int, "9"),
        Token.init(TokenType.Semicolon, ";"),
        //
        Token.init(TokenType.Eof, ""),
    };
    var lexer = Lexer.init(testing.allocator, input);
    lexer.read_char();
    for (expected) |expected_token| {
        const tok = lexer.next_token();
        // debug.print("atok: {any}\netok: {any}\n\n", .{ tok, expected_token });
        try testing.expect(tok.t == expected_token.t);
        try testing.expect(mem.eql(u8, tok.literal, expected_token.literal));
    }
}
