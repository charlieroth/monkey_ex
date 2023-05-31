defmodule MonkeyEx.Evaluator do
  alias MonkeyEx.Ast.IfExpression
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

  def eval(%Ast.BlockStatement{} = ast_node) do
    eval_block_statement(ast_node)
  end

  def eval(%Ast.IfExpression{} = ast_node) do
    eval_if_expression(ast_node)
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

  def eval(%Ast.InfixExpression{} = ast_node) do
    left_expression = eval(ast_node.left)
    right_expression = eval(ast_node.right)
    eval_infix_expression(left_expression, ast_node.operator, right_expression)
  end

  defp eval_program(program, last_eval \\ nil) do
    do_eval_program(program.statements, last_eval)
  end

  defp do_eval_program([], last_eval), do: last_eval

  defp do_eval_program([statement | rest], _last_eval) do
    value = eval(statement)

    case value do
      # %ReturnValue{} -> value.value
      # %Error{} -> value
      _ -> do_eval_program(rest, value)
    end
  end

  defp eval_infix_expression(left, operator, right) do
    case operator do
      "+" -> %Object.Integer{value: left.value + right.value}
      "-" -> %Object.Integer{value: left.value - right.value}
      "*" -> %Object.Integer{value: left.value * right.value}
      "/" -> %Object.Integer{value: left.value / right.value}
      ">" -> %Object.Boolean{value: left.value > right.value}
      "<" -> %Object.Boolean{value: left.value < right.value}
      "==" -> %Object.Boolean{value: left.value == right.value}
      "!=" -> %Object.Boolean{value: left.value != right.value}
      _ -> raise "Invalid infix operator: #{operator}"
    end
  end

  defp eval_prefix_expression(operator, right) do
    case operator do
      "!" ->
        eval_bang_operator_expression(right)

      "-" ->
        eval_minus_operator_expression(right)

      _ ->
        # TODO(charlieroth): Should this return `nil`? Error handling?
        nil
    end
  end

  defp eval_block_statement(block, last_eval \\ nil) do
    do_eval_block_statement(block.statements, last_eval)
  end

  defp do_eval_block_statement([], last_eval), do: last_eval

  defp do_eval_block_statement([statement | rest], _last_eval) do
    value = eval(statement)

    case value do
      # %ReturnValue{} -> value
      # %Error{} -> value
      _ -> do_eval_block_statement(rest, value)
    end
  end

  @spec eval_if_expression(%IfExpression{}) :: any()
  defp eval_if_expression(expression) do
    evaluated_condition = eval(expression.condition)

    cond do
      # is_error(evaluated_condition) -> condition
      is_truthy(evaluated_condition) -> eval(expression.consequence)
      expression.alternative != nil -> eval(expression.alternative)
      true -> %Object.Null{}
    end
  end

  defp eval_bang_operator_expression(right) do
    case right do
      %Object.Boolean{value: true} ->
        %Object.Boolean{value: false}

      %Object.Boolean{value: false} ->
        %Object.Boolean{value: true}

      _ ->
        %Object.Boolean{value: false}
    end
  end

  defp eval_minus_operator_expression(right) do
    case right do
      %Object.Integer{} ->
        %Object.Integer{value: -right.value}

      _ ->
        raise "unknown operator: -#{Object.type(right)}"
    end
  end

  defp is_truthy(object) do
    case object do
      %Object.Boolean{value: true} -> true
      %Object.Boolean{value: false} -> false
      %Object.Null{} -> false
      _ -> true
    end
  end
end
