defmodule ParserTest do
  use ExUnit.Case

  alias MonkeyEx.Parser

  alias MonkeyEx.Ast.{
    ExpressionStatement,
    Identifier,
    IntegerLiteral
  }

  describe "init/1" do
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

      parser = Parser.init(tokens)
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
        |> Parser.init()
        |> Parser.parse([])

      assert parser.tokens == []
      assert parser.current_token == :eof
      assert parser.peek_token == nil
      assert length(program.statements) == 2
    end

    test "parses and produces error for missing identifier" do
      tokens = [
        :let,
        # {:ident, "five"},
        :assign,
        {:int, "5"},
        :semicolon,
        :eof
      ]

      {parser, _program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      assert length(parser.errors) == 1
      err = Enum.at(parser.errors, 0)
      assert err =~ "Expected token #{inspect(:ident)}"
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
        {:int, "993322"},
        :semicolon,
        :eof
      ]

      {parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      assert parser.current_token == :eof
      assert parser.peek_token == nil
      assert length(program.statements) == 3
    end

    test "parses simple expression statement" do
      tokens = [
        {:ident, "foobar"},
        :semicolon,
        :eof
      ]

      {_parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      expression_statement = Enum.at(program.statements, 0)

      assert expression_statement == %ExpressionStatement{
               token: {:ident, "foobar"},
               expression: %Identifier{
                 token: {:ident, "foobar"},
                 value: "foobar"
               }
             }
    end

    test "integer literals" do
      tokens = [
        {:int, "5"},
        :semicolon,
        :eof
      ]

      {_parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      integer_literal_statement = Enum.at(program.statements, 0)

      assert integer_literal_statement == %ExpressionStatement{
               token: {:int, "5"},
               expression: %IntegerLiteral{token: {:int, "5"}, value: 5}
             }
    end
  end
end
