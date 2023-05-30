defmodule MonkeyEx.Evaluator do
  alias MonkeyEx.Ast
  alias MonkeyEx.Object

  def eval(%Ast.Program{} = ast_node) do
    eval_program(ast_node)
  end

  def eval(%Ast.ExpressionStatement{} = ast_node) do
    eval(ast_node.expression)
  end

  def eval(%Ast.IntegerLiteral{} = ast_node) do
    %Object.Integer{value: ast_node.value}
  end

  def eval(%Ast.BooleanLiteral{} = ast_node) do
    %Object.Boolean{value: ast_node.value}
  end

  defp eval_program(program, last_eval \\ nil) do
    do_eval_program(program.statements, last_eval)
  end

  defp do_eval_program([], last_eval), do: last_eval

  defp do_eval_program([statement | rest], _last_eval) do
    value = eval(statement)

    case value do
      _ -> do_eval_program(rest, value)
    end
  end
end
