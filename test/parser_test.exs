defmodule ParserTest do
  use ExUnit.Case

  alias Parser
  alias Lexer
  alias Token
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
  end
end
