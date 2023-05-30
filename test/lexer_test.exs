defmodule LexerTest do
  use ExUnit.Case

  alias MonkeyEx.Lexer

  describe "init/1" do
    test "tokenizes simple set of syntax symbols" do
      result = "=+(){},;" |> Lexer.init()

      assert result == [
               :assign,
               :plus,
               :lparen,
               :rparen,
               :lbrace,
               :rbrace,
               :comma,
               :semicolon,
               :eof
             ]
    end

    test "tokenizes variable declarations" do
      input = """
      let five = 5;
      let ten = 10;
      let returnfds = 11;
      """

      result = input |> Lexer.init()

      assert result == [
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
               :let,
               {:ident, "returnfds"},
               :assign,
               {:int, "11"},
               :semicolon,
               :eof
             ]
    end

    test "tokenizes function expression" do
      input = """
      let add = fn(x, y) {
        x + y;
      };
      """

      result = input |> Lexer.init()

      assert result == [
               :let,
               {:ident, "add"},
               :assign,
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
               :semicolon,
               :eof
             ]
    end

    test "tokenizes function call, result assigned to variable" do
      input = """
      let result = add(five, ten);
      """

      result = input |> Lexer.init()

      assert result == [
               :let,
               {:ident, "result"},
               :assign,
               {:ident, "add"},
               :lparen,
               {:ident, "five"},
               :comma,
               {:ident, "ten"},
               :rparen,
               :semicolon,
               :eof
             ]
    end

    test "tokenizes operators" do
      input = """
      !-/*5;
      5 < 10 > 5;
      """

      result = input |> Lexer.init()

      assert result == [
               :bang,
               :minus,
               :slash,
               :asterisk,
               {:int, "5"},
               :semicolon,
               {:int, "5"},
               :less_than,
               {:int, "10"},
               :greater_than,
               {:int, "5"},
               :semicolon,
               :eof
             ]
    end

    test "tokenizes if/else statement" do
      input = """
      if (5 < 10) {
        return true;
      } else {
        return false;
      }
      """

      result = input |> Lexer.init()

      assert result == [
               :if,
               :lparen,
               {:int, "5"},
               :less_than,
               {:int, "10"},
               :rparen,
               :lbrace,
               :return,
               true,
               :semicolon,
               :rbrace,
               :else,
               :lbrace,
               :return,
               false,
               :semicolon,
               :rbrace,
               :eof
             ]
    end

    test "tokenizes equivalence operators" do
      input = """
      10 == 10;
      11 != 10;
      """

      result = input |> Lexer.init()

      assert result == [
               {:int, "10"},
               :equal_equal,
               {:int, "10"},
               :semicolon,
               {:int, "11"},
               :not_equal,
               {:int, "10"},
               :semicolon,
               :eof
             ]
    end

    test "tokenizes return statements" do
      input = """
      return 5;
      return 10;
      return add(15);
      """

      result = input |> Lexer.init()

      assert result == [
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
    end
  end
end
