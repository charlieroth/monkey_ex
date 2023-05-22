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
        Token.init(.assign, "="),
        Token.init(.plus, "+"),
        Token.init(.l_paren, "("),
        Token.init(.r_paren, ")"),
        Token.init(.l_brace, "{"),
        Token.init(.r_brace, "}"),
        Token.init(.comma, ","),
        Token.init(.semicolon, ";"),
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
        Token.init(.let, "let"),
        Token.init(.ident, "five"),
        Token.init(.assign, "="),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),
        // let ten = 10;
        Token.init(.let, "let"),
        Token.init(.ident, "ten"),
        Token.init(.assign, "="),
        Token.init(.int, "10"),
        Token.init(.semicolon, ";"),
        // let add = fn(x, y) { x + y; };
        Token.init(.let, "let"),
        Token.init(.ident, "add"),
        Token.init(.assign, "="),
        Token.init(.function, "fn"),
        Token.init(.l_paren, "("),
        Token.init(.ident, "x"),
        Token.init(.comma, ","),
        Token.init(.ident, "y"),
        Token.init(.r_paren, ")"),
        Token.init(.l_brace, "{"),
        Token.init(.ident, "x"),
        Token.init(.plus, "+"),
        Token.init(.ident, "y"),
        Token.init(.semicolon, ";"),
        Token.init(.r_brace, "}"),
        Token.init(.semicolon, ";"),
        // let result = add(five, ten);
        Token.init(.let, "let"),
        Token.init(.ident, "result"),
        Token.init(.assign, "="),
        Token.init(.ident, "add"),
        Token.init(.l_paren, "("),
        Token.init(.ident, "five"),
        Token.init(.comma, ","),
        Token.init(.ident, "ten"),
        Token.init(.r_paren, ")"),
        Token.init(.semicolon, ";"),
        Token.init(.eof, ""),
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
        Token.init(.let, "let"),
        Token.init(.ident, "five"),
        Token.init(.assign, "="),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),
        // let ten = 10;
        Token.init(.let, "let"),
        Token.init(.ident, "ten"),
        Token.init(.assign, "="),
        Token.init(.int, "10"),
        Token.init(.semicolon, ";"),
        // let add = fn(x, y) { x + y; };
        Token.init(.let, "let"),
        Token.init(.ident, "add"),
        Token.init(.assign, "="),
        Token.init(.function, "fn"),
        Token.init(.l_paren, "("),
        Token.init(.ident, "x"),
        Token.init(.comma, ","),
        Token.init(.ident, "y"),
        Token.init(.r_paren, ")"),
        Token.init(.l_brace, "{"),
        Token.init(.ident, "x"),
        Token.init(.plus, "+"),
        Token.init(.ident, "y"),
        Token.init(.semicolon, ";"),
        Token.init(.r_brace, "}"),
        Token.init(.semicolon, ";"),
        // let result = add(five, ten);
        Token.init(.let, "let"),
        Token.init(.ident, "result"),
        Token.init(.assign, "="),
        Token.init(.ident, "add"),
        Token.init(.l_paren, "("),
        Token.init(.ident, "five"),
        Token.init(.comma, ","),
        Token.init(.ident, "ten"),
        Token.init(.r_paren, ")"),
        Token.init(.semicolon, ";"),
        // !-/*5;
        Token.init(.bang, "!"),
        Token.init(.minus, "-"),
        Token.init(.slash, "/"),
        Token.init(.asterisk, "*"),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),
        // 5 < 10 > 5;
        Token.init(.int, "5"),
        Token.init(.less_than, "<"),
        Token.init(.int, "10"),
        Token.init(.greater_than, ">"),
        Token.init(.int, "5"),
        Token.init(.semicolon, ";"),
        //if (5 < 10) {
        //  return true;
        //} else {
        //  return false;
        //}
        Token.init(._if, "if"),
        Token.init(.l_paren, "("),
        Token.init(.int, "5"),
        Token.init(.less_than, "<"),
        Token.init(.int, "10"),
        Token.init(.r_paren, ")"),
        Token.init(.l_brace, "{"),
        Token.init(._return, "return"),
        Token.init(._true, "true"),
        Token.init(.semicolon, ";"),
        Token.init(.r_brace, "}"),
        Token.init(._else, "else"),
        Token.init(.l_brace, "{"),
        Token.init(._return, "return"),
        Token.init(._false, "false"),
        Token.init(.semicolon, ";"),
        Token.init(.r_brace, "}"),
        //10 == 10;
        //10 != 9;
        Token.init(.int, "10"),
        Token.init(.equal_equal, "=="),
        Token.init(.int, "10"),
        Token.init(.semicolon, ";"),
        Token.init(.int, "10"),
        Token.init(.not_equal, "!="),
        Token.init(.int, "9"),
        Token.init(.semicolon, ";"),
        //
        Token.init(.eof, ""),
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
