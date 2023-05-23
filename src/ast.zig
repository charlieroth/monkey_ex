const std = @import("std");
const token = @import("token.zig");

const mem = std.mem;
const heap = std.heap;
const debug = std.debug;
const testing = std.testing;

// ===== Statements =====
pub const LetStatement = struct {
    tok: token.Token,
    name: Identifier,

    pub fn statement_node(self: LetStatement) void {
        _ = self;
        return;
    }

    pub fn token_literal(self: LetStatement) []const u8 {
        return self.tok.literal;
    }
};

pub const Statement = union(enum) {
    let: LetStatement,

    pub fn statement_node() void {}

    pub fn token_literal(self: Statement) []const u8 {
        return switch (self) {
            .let => |let| {
                return let.token_literal();
            },
        };
    }
};

// ===== Expressions =====
pub const Identifier = struct {
    tok: token.Token,
    value: []const u8,

    pub fn expression_node(self: Identifier) void {
        _ = self;
        return;
    }

    pub fn token_literal(self: Identifier) []const u8 {
        return self.tok.literal;
    }
};

pub const Expression = union(enum) {
    identifier: Identifier,

    pub fn expression_node() void {}

    pub fn token_literal(self: Expression) []const u8 {
        switch (self) {
            .identifier => |identifier| {
                return identifier.token_literal();
            },
        }
    }
};

// ===== Program =====
pub const Program = struct {
    statements: std.ArrayList(Statement),
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator) Program {
        return Program{
            .statements = std.ArrayList(Statement).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Program) void {
        self.statements.deinit();
    }

    pub fn token_literal(self: *Program) []const u8 {
        if (self.statements.len > 0) {
            return self.statements.items[0].token_literal();
        } else {
            return "";
        }
    }
};
