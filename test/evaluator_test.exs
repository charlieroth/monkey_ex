defmodule EvaluatorTest do
  use ExUnit.Case
  alias MonkeyEx.{Evaluator, Parser, Lexer}
  alias MonkeyEx.Object

  describe "eval/1" do
    test "evaluate integers" do
      inputs = [
        {"5", %Object.Integer{value: 5}},
        {"10", %Object.Integer{value: 10}}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated == expected
      end)
    end

    test "evaluate booleans" do
      inputs = [
        {"true", %Object.Boolean{value: true}},
        {"false", %Object.Boolean{value: false}}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated == expected
      end)
    end

    test "evaluate 'bang' operator" do
      inputs = [
        {"!true", false},
        {"!false", true},
        {"!5", false},
        {"!!true", true},
        {"!!false", false},
        {"!!5", true}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end

    test "evaluate '-' operator" do
      inputs = [
        {"5", 5},
        {"10", 10},
        {"-5", -5},
        {"-10", -10}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end

    test "evaluate integer infix operators" do
      inputs = [
        {"5 + 5 + 5 + 5 - 10", 10},
        {"2 * 2 * 2 * 2 * 2", 32},
        {"-50 + 100 + -50", 0},
        {"5 * 2 + 10", 20},
        {"5 + 2 * 10", 25},
        {"20 + 2 * -10", 0},
        {"50 / 2 * 2 + 10", 60},
        {"2 * (5 + 10)", 30},
        {"3 * 3 * 3 + 10", 37},
        {"3 * (3 * 3) + 10", 37},
        {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end

    test "evaluate boolean infix operators" do
      inputs = [
        {"1 < 2", true},
        {"1 > 2", false},
        {"1 == 1", true},
        {"1 == 2", false},
        {"1 != 1", false},
        {"1 != 2", true}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end

    test "evaluate boolean expressions" do
      inputs = [
        {"true == true", true},
        {"false == false", true},
        {"true == false", false},
        {"true != false", true},
        {"false != true", true},
        {"(1 < 2) == true", true},
        {"(1 < 2) == false", false},
        {"(1 > 2) == true", false},
        {"(1 > 2) == false", true}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end

    test "evaluate if/else expressions" do
      inputs = [
        {"if (true) { 10 }", 10},
        {"if (false) { 10 }", nil},
        {"if (1) { 10 }", 10},
        {"if (1 < 2) { 10 }", 10},
        {"if (1 > 2) { 10 }", nil},
        {"if (1 > 2) { 10 } else { 20 }", 20},
        {"if (1 < 2) { 10 } else { 20 }", 10}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end

    test "evaluate return statements" do
      inputs = [
        {"return 10;", 10},
        {"return 10; 9;", 10},
        {"return 2 * 5; 9;", 10},
        {"9; return 2 * 5; 9;", 10},
        {"if (10 > 1) { if (10 > 1) { return 10; } return 1; }", 10}
      ]

      Enum.each(inputs, fn {input, expected} ->
        {_parser, program} =
          input
          |> Lexer.init()
          |> Parser.init()
          |> Parser.parse([])

        evaluated = Evaluator.eval(program)
        assert evaluated.value == expected
      end)
    end
  end
end
