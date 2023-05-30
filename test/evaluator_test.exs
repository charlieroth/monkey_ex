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
  end
end
