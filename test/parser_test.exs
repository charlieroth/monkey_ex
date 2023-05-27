defmodule ParserTest do
  use ExUnit.Case

  alias MonkeyEx.{Parser, Token}
  alias MonkeyEx.Ast.ExpressionStatement

  describe "from_tokens/1" do
    test "creates parser with tokens" do
      tokens = [
        :let,
        {:ident, "five"},
        :assign,
        {:int, "5"},
        :semicolon,
        :let,
        {:ident, "ten"},
        :assign,
        {:int, "10"},
        :semicolon,
        :eof
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
        :let,
        {:ident, "five"},
        :assign,
        {:int, "5"},
        :semicolon,
        :let,
        {:ident, "ten"},
        :assign,
        {:int, "10"},
        :semicolon,
        :eof
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
        :let,
        # {:ident, "five"},
        :assign,
        {:int, literal: "5"},
        :semicolon,
        :eof
      ]

      {parser, _program} =
        tokens
        |> Parser.from_tokens()
        |> Parser.parse([])

      assert length(parser.errors) == 1
    end

    test "parses return statements" do
      tokens = [
        :return,
        {:int, "5"},
        :semicolon,
        :return,
        {:int, "10"},
        :semicolon,
        :return,
        {:ident, "add"},
        :lparen,
        {:int, "15"},
        :rparen,
        :semicolon,
        :eof
      ]

      {parser, program} =
        tokens
        |> Parser.from_tokens()
        |> Parser.parse([])

      assert parser.current_token == %Token{type: :eof, literal: ""}
      assert parser.peek_token == nil
      assert length(program.statements) == 3

      all_return_statements =
        Enum.all?(
          program.statements,
          fn s -> s.return_value != nil end
        )

      assert all_return_statements
    end

    test "parses simple expression statement" do
      tokens = [
        {:ident, "foobar"},
        :semicolon,
        :eof
      ]

      {parser, program} =
        tokens
        |> Parser.from_tokens()
        |> Parser.parse([])

      expression_statement = Enum.at(program.statements, 0)
      IO.inspect(program.statements, 0)
      assert true == true
    end
  end
end
