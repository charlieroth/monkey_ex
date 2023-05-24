defmodule ParserTest do
  use ExUnit.Case

  alias Mirlang.{Parser, Lexer, Token}

  alias Ast.{
    Program,
    LetStatement,
    Identifier,
    IntegerLiteral
  }

  describe "from_tokens/1" do
    test "creates parser with tokens" do
      tokens = [
        %Token{type: :let, literal: "let"},
        %Token{type: :ident, literal: "five"},
        %Token{type: :assign, literal: "="},
        %Token{type: :int, literal: "5"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :let, literal: "let"},
        %Token{type: :ident, literal: "ten"},
        %Token{type: :assign, literal: "="},
        %Token{type: :int, literal: "10"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :eof, literal: ""}
      ]

      parser = Parser.from_tokens(tokens)
      remaining_tokens = tokens |> Enum.drop(2)

      assert parser.tokens == remaining_tokens
      assert parser.current_token == tokens |> Enum.at(0)
      assert parser.peek_token == tokens |> Enum.at(1)
    end
  end

  describe "parse/2" do
    test "parses variable declarations" do
      tokens = [
        %Token{type: :let, literal: "let"},
        %Token{type: :ident, literal: "five"},
        %Token{type: :assign, literal: "="},
        %Token{type: :int, literal: "5"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :let, literal: "let"},
        %Token{type: :ident, literal: "ten"},
        %Token{type: :assign, literal: "="},
        %Token{type: :int, literal: "10"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :eof, literal: ""}
      ]

      {parser, program} =
        tokens
        |> Parser.from_tokens()
        |> Parser.parse([])

      assert parser.tokens == []
      assert parser.current_token == %Token{type: :eof, literal: ""}
      assert parser.peek_token == nil
      assert length(program.statements) == 2
    end

    test "parses and produces error for missing identifier" do
      tokens = [
        %Token{type: :let, literal: "let"},
        # %Token{type: :ident, literal: "five"},
        %Token{type: :assign, literal: "="},
        %Token{type: :int, literal: "5"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :eof, literal: ""}
      ]

      {parser, program} =
        tokens
        |> Parser.from_tokens()
        |> Parser.parse([])

      assert length(parser.errors) == 1
    end

    test "parses return statements" do
      tokens = [
        %Token{type: :return, literal: "return"},
        %Token{type: :int, literal: "5"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :return, literal: "return"},
        %Token{type: :int, literal: "10"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :return, literal: "return"},
        %Token{type: :ident, literal: "add"},
        %Token{type: :lparen, literal: "("},
        %Token{type: :int, literal: "15"},
        %Token{type: :rparen, literal: ")"},
        %Token{type: :semicolon, literal: ";"},
        %Token{type: :eof, literal: ""}
      ]

      {parser, program} =
        tokens
        |> Parser.from_tokens()
        |> Parser.parse([])

      assert parser.current_token == %Token{type: :eof, literal: ""}
      assert parser.peek_token == nil
      assert length(program.statements) == 3

      all_return_statements = Enum.all?(program.statements, fn s -> s.return_value != nil end)
      assert all_return_statements
    end
  end
end
