defmodule ParserTest do
  use ExUnit.Case

  alias MonkeyEx.Parser

  alias MonkeyEx.Ast.{
    Program,
    ExpressionStatement,
    PrefixExpression,
    InfixExpression,
    Identifier,
    IntegerLiteral,
    BooleanLiteral
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

      assert parser.errors == [
               "No prefix function for token: assign",
               "Expected token :ident, got :assign"
             ]
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

    test "parse prefix expressions" do
      tokens = [
        :bang,
        {:int, "5"},
        :semicolon,
        :minus,
        {:int, "15"},
        :semicolon,
        :bang,
        true,
        :semicolon,
        :bang,
        false,
        :semicolon,
        :eof
      ]

      {_parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      assert program.statements == [
               %ExpressionStatement{
                 token: :bang,
                 expression: %PrefixExpression{
                   token: :bang,
                   operator: "!",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: :minus,
                 expression: %PrefixExpression{
                   token: :minus,
                   operator: "-",
                   right: %IntegerLiteral{token: {:int, "15"}, value: 15}
                 }
               },
               %ExpressionStatement{
                 token: :bang,
                 expression: %PrefixExpression{
                   token: :bang,
                   operator: "!",
                   right: %BooleanLiteral{token: true, value: true}
                 }
               },
               %ExpressionStatement{
                 token: :bang,
                 expression: %PrefixExpression{
                   token: :bang,
                   operator: "!",
                   right: %BooleanLiteral{token: false, value: false}
                 }
               }
             ]
    end

    test "parse infix expressions" do
      tokens = [
        {:int, "5"},
        :plus,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :minus,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :asterisk,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :slash,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :greater_than,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :less_than,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :equal_equal,
        {:int, "5"},
        :semicolon,
        {:int, "5"},
        :not_equal,
        {:int, "6"},
        :semicolon,
        true,
        :equal_equal,
        true,
        :semicolon,
        true,
        :not_equal,
        false,
        :semicolon,
        false,
        :equal_equal,
        false,
        :semicolon,
        :eof
      ]

      {_parser, program} = tokens |> Parser.init() |> Parser.parse([])

      assert program.statements == [
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :plus,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "+",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :minus,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "-",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :asterisk,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "*",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :slash,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "/",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :greater_than,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: ">",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :less_than,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "<",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :equal_equal,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "==",
                   right: %IntegerLiteral{token: {:int, "5"}, value: 5}
                 }
               },
               %ExpressionStatement{
                 token: {:int, "5"},
                 expression: %InfixExpression{
                   token: :not_equal,
                   left: %IntegerLiteral{token: {:int, "5"}, value: 5},
                   operator: "!=",
                   right: %IntegerLiteral{token: {:int, "6"}, value: 6}
                 }
               },
               %ExpressionStatement{
                 token: true,
                 expression: %InfixExpression{
                   token: :equal_equal,
                   left: %BooleanLiteral{token: true, value: true},
                   operator: "==",
                   right: %BooleanLiteral{token: true, value: true}
                 }
               },
               %ExpressionStatement{
                 token: true,
                 expression: %InfixExpression{
                   token: :not_equal,
                   left: %BooleanLiteral{token: true, value: true},
                   operator: "!=",
                   right: %BooleanLiteral{token: false, value: false}
                 }
               },
               %ExpressionStatement{
                 token: false,
                 expression: %InfixExpression{
                   token: :equal_equal,
                   left: %BooleanLiteral{token: false, value: false},
                   operator: "==",
                   right: %BooleanLiteral{token: false, value: false}
                 }
               }
             ]
    end

    test "operator precedence parsing" do
      inputs = [
        {
          [:minus, {:ident, "a"}, :asterisk, {:ident, "b"}, :semicolon, :eof],
          "((-a) * b)"
        },
        {
          [:bang, :minus, {:ident, "a"}, :semicolon, :eof],
          "(!(-a))"
        },
        {
          [{:ident, "a"}, :plus, {:ident, "b"}, :plus, {:ident, "c"}, :semicolon, :eof],
          "((a + b) + c)"
        },
        {
          [{:ident, "a"}, :plus, {:ident, "b"}, :minus, {:ident, "c"}, :semicolon, :eof],
          "((a + b) - c)"
        },
        {
          [{:ident, "a"}, :asterisk, {:ident, "b"}, :asterisk, {:ident, "c"}, :semicolon, :eof],
          "((a * b) * c)"
        },
        {
          [{:ident, "a"}, :asterisk, {:ident, "b"}, :slash, {:ident, "c"}, :semicolon, :eof],
          "((a * b) / c)"
        },
        {
          [{:ident, "a"}, :plus, {:ident, "b"}, :slash, {:ident, "c"}, :semicolon, :eof],
          "(a + (b / c))"
        },
        {
          [
            {:ident, "a"},
            :plus,
            {:ident, "b"},
            :asterisk,
            {:ident, "c"},
            :plus,
            {:ident, "d"},
            :slash,
            {:ident, "e"},
            :minus,
            {:ident, "f"},
            :semicolon,
            :eof
          ],
          "(((a + (b * c)) + (d / e)) - f)"
        },
        {
          [
            {:int, "3"},
            :plus,
            {:int, "4"},
            :semicolon,
            :minus,
            {:int, "5"},
            :asterisk,
            {:int, "5"},
            :semicolon,
            :eof
          ],
          "(3 + 4)((-5) * 5)"
        },
        {
          [
            {:int, "5"},
            :greater_than,
            {:int, "4"},
            :equal_equal,
            {:int, "3"},
            :less_than,
            {:int, "4"},
            :eof
          ],
          "((5 > 4) == (3 < 4))"
        },
        {
          [
            {:int, "5"},
            :less_than,
            {:int, "4"},
            :not_equal,
            {:int, "3"},
            :greater_than,
            {:int, "4"},
            :eof
          ],
          "((5 < 4) != (3 > 4))"
        },
        {
          [
            {:int, "3"},
            :plus,
            {:int, "4"},
            :asterisk,
            {:int, "5"},
            :equal_equal,
            {:int, "3"},
            :asterisk,
            {:int, "1"},
            :plus,
            {:int, "4"},
            :asterisk,
            {:int, "5"},
            :eof
          ],
          "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"
        },
        {
          [true, :semicolon, :eof],
          "true"
        },
        {
          [false, :semicolon, :eof],
          "false"
        },
        {
          [{:int, "3"}, :greater_than, {:int, "5"}, :equal_equal, false, :semicolon, :eof],
          "((3 > 5) == false)"
        },
        {
          [{:int, "3"}, :less_than, {:int, "5"}, :equal_equal, true, :semicolon, :eof],
          "((3 < 5) == true)"
        }
      ]

      inputs
      |> Enum.each(fn {tokens, expected_program_string} ->
        {_parser, program} =
          tokens
          |> Parser.init()
          |> Parser.parse([])

        assert Program.string(program) == expected_program_string
      end)
    end

    test "grouped expressions" do
      inputs = [
        {
          [
            {:int, "1"},
            :plus,
            :lparen,
            {:int, "2"},
            :plus,
            {:int, "3"},
            :rparen,
            :plus,
            {:int, "4"},
            :semicolon,
            :eof
          ],
          "((1 + (2 + 3)) + 4)"
        },
        {
          [
            :lparen,
            {:int, "5"},
            :plus,
            {:int, "5"},
            :rparen,
            :asterisk,
            {:int, "2"},
            :semicolon,
            :eof
          ],
          "((5 + 5) * 2)"
        },
        {
          [
            {:int, "2"},
            :slash,
            :lparen,
            {:int, "5"},
            :plus,
            {:int, "5"},
            :rparen,
            :semicolon,
            :eof
          ],
          "(2 / (5 + 5))"
        },
        {
          [
            :minus,
            :lparen,
            {:int, "5"},
            :plus,
            {:int, "5"},
            :rparen,
            :semicolon,
            :eof
          ],
          "(-(5 + 5))"
        },
        {
          [
            :bang,
            :lparen,
            true,
            :equal_equal,
            true,
            :rparen,
            :semicolon,
            :eof
          ],
          "(!(true == true))"
        }
      ]

      inputs
      |> Enum.each(fn {tokens, expected_program_string} ->
        {_parser, program} =
          tokens
          |> Parser.init()
          |> Parser.parse([])

        assert Program.string(program) == expected_program_string
      end)
    end

    test "if expression" do
      tokens = [
        :if,
        :lparen,
        {:ident, "x"},
        :less_than,
        {:ident, "y"},
        :rparen,
        :lbrace,
        {:ident, "x"},
        :rbrace,
        :eof
      ]

      {_parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      assert Program.string(program) == "if (x < y) x"
    end

    test "if/else expression" do
      tokens = [
        :if,
        :lparen,
        {:ident, "x"},
        :less_than,
        {:ident, "y"},
        :rparen,
        :lbrace,
        {:ident, "x"},
        :rbrace,
        :else,
        :lbrace,
        {:ident, "y"},
        :rbrace,
        :eof
      ]

      {_parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      assert Program.string(program) == "if (x < y) x else y"
    end

    test "function literals" do
      tokens = [
        :fn,
        :lparen,
        {:ident, "x"},
        :comma,
        {:ident, "y"},
        :rparen,
        :lbrace,
        {:ident, "x"},
        :plus,
        {:ident, "y"},
        :semicolon,
        :rbrace,
        :eof
      ]

      {_parser, program} =
        tokens
        |> Parser.init()
        |> Parser.parse([])

      assert Program.string(program) == "fn(x, y) (x + y)"
    end

    test "call expressions" do
      inputs = [
        {
          [
            {:ident, "add"},
            :lparen,
            {:int, "1"},
            :comma,
            {:int, "2"},
            :asterisk,
            {:int, "3"},
            :comma,
            {:int, "4"},
            :plus,
            {:int, "5"},
            :rparen,
            :eof
          ],
          "add(1, (2 * 3), (4 + 5))"
        },
        {
          [
            {:ident, "a"},
            :plus,
            {:ident, "add"},
            :lparen,
            {:ident, "b"},
            :asterisk,
            {:ident, "c"},
            :rparen,
            :plus,
            {:ident, "d"},
            :eof
          ],
          "((a + add((b * c))) + d)"
        },
        {
          [
            {:ident, "add"},
            :lparen,
            {:ident, "a"},
            :comma,
            {:ident, "b"},
            :comma,
            {:int, "1"},
            :comma,
            {:int, "2"},
            :asterisk,
            {:int, "3"},
            :comma,
            {:int, "4"},
            :plus,
            {:int, "5"},
            :comma,
            {:ident, "add"},
            :lparen,
            {:int, "6"},
            :comma,
            {:int, "7"},
            :asterisk,
            {:int, "8"},
            :rparen,
            :rparen,
            :eof
          ],
          "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
        },
        {
          [
            {:ident, "add"},
            :lparen,
            {:ident, "a"},
            :plus,
            {:ident, "b"},
            :plus,
            {:ident, "c"},
            :asterisk,
            {:ident, "d"},
            :slash,
            {:ident, "f"},
            :plus,
            {:ident, "g"},
            :rparen,
            :eof
          ],
          "add((((a + b) + ((c * d) / f)) + g))"
        }
      ]

      Enum.each(inputs, fn {tokens, expected_program_string} ->
        {_parser, program} =
          tokens
          |> Parser.init()
          |> Parser.parse([])

        assert Program.string(program) == expected_program_string
      end)
    end
  end
end
