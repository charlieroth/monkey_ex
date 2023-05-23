const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const debug = std.debug;
const ast = @import("ast.zig");
const token = @import("token.zig");
const Lexer = @import("lexer.zig").Lexer;
const Token = token.Token;
const TokenType = token.TokenType;
const Program = ast.Program;

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    peek_token: Token,
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator, lexer: *Lexer) Parser {
        var parser = Parser{
            .lexer = lexer,
            .allocator = allocator,
            .current_token = undefined,
            .peek_token = undefined,
        };

        // read two tokens to populate current_token and peek_token
        parser.next_token();
        parser.next_token();

        return parser;
    }

    pub fn next_token(self: *Parser) void {
        self.current_token = self.peek_token;
        self.peek_token = self.lexer.next_token();
    }

    pub fn parse_program(self: *Parser) !Program {
        var program = Program.init(self.allocator);
        while (self.current_token.t != TokenType.eof) {
            var statement: ?ast.Statement = self.parse_statement();
            if (statement) |s| {
                try program.statements.append(s);
            }
            self.next_token();
        }
        return program;
    }

    pub fn parse_statement(self: *Parser) ?ast.Statement {
        return switch (self.current_token.t) {
            .let => self.parse_let_statement(),
            else => null,
        };
    }

    pub fn parse_let_statement(self: *Parser) ?ast.Statement {
        if (!self.expect_peek(TokenType.ident)) {
            return null;
        }

        var statement = ast.Statement{
            .let = ast.LetStatement{
                .tok = self.current_token,
                .name = ast.Identifier{
                    .tok = self.current_token,
                    .value = self.current_token.literal,
                },
            },
        };

        if (!self.expect_peek(TokenType.assign)) {
            return null;
        }

        // TODO(charlieroth): Skipping expressions until we encounter
        // a semicolon
        while (!self.current_token_is(TokenType.semicolon)) {
            self.next_token();
        }

        return statement;
    }

    fn current_token_is(self: *Parser, token_type: TokenType) bool {
        return self.current_token.t == token_type;
    }

    fn peek_token_is(self: *Parser, token_type: TokenType) bool {
        return self.peek_token.t == token_type;
    }

    fn expect_peek(self: *Parser, token_type: TokenType) bool {
        if (self.peek_token_is(token_type)) {
            self.next_token();
            return true;
        } else {
            return false;
        }
    }
};

test "parser: let statements" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;
    const expected_identifiers = [3][]const u8{
        "foobar",
        "y",
        "x",
    };

    const allocator = testing.allocator;
    var lexer: Lexer = Lexer.init(allocator, input);
    var parser: Parser = Parser.init(allocator, &lexer);
    var program = try parser.parse_program();
    defer program.deinit();

    try testing.expect(program.statements.items.len == 3);

    debug.print("\n", .{});
    for (expected_identifiers) |identifier| {
        var statement: ast.Statement = program.statements.pop();

        debug.print("identifier: {s}\n", .{identifier});
        debug.print("statement.token_literal(): {s}\n", .{statement.token_literal()});
        debug.print("statement.tok: {s}\n", .{statement.let.token_literal()});
        debug.print("statement.name: {s}\n", .{statement.let.name.value});
        // try testing.expect(test_let_statement(&statement, identifier) == true);
    }
}

fn test_let_statement(statement: *ast.Statement, identifier: []const u8) bool {
    if (!mem.eql(u8, statement.token_literal(), "let")) {
        return false;
    }

    var let_statement: ast.LetStatement = statement.let;

    if (!mem.eql(u8, let_statement.name.value, identifier)) {
        return false;
    }

    if (!mem.eql(u8, let_statement.name.token_literal(), identifier)) {
        return false;
    }

    return true;
}
