defmodule MonkeyEx.Evaluator do
  alias MonkeyEx.Ast
  alias MonkeyEx.Object

  @type ast_nodes ::
          %Ast.Program{}
          | %Ast.ExpressionStatement{}
          | %Ast.IntegerLiteral{}
          | %Ast.BooleanLiteral{}
          | %Ast.PrefixExpression{}

  @type objects ::
          %Object.Integer{}
          | %Object.Boolean{}

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

  def eval(%Ast.PrefixExpression{} = ast_node) do
    right_expression = eval(ast_node.right)
    eval_prefix_expression(ast_node.operator, right_expression)
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

  defp eval_prefix_expression(operator, expression) do
    case operator do
      "!" ->
        eval_bang_operator_expression(expression)

      _ ->
        # TODO(charlieroth): Should this return `nil`? Error handling?
        nil
    end
  end

  defp eval_bang_operator_expression(expression) do
    case expression do
      %Object.Boolean{value: true} ->
        %Object.Boolean{value: false}

      %Object.Boolean{value: false} ->
        %Object.Boolean{value: true}

      _ ->
        %Object.Boolean{value: false}
    end
  end
end
