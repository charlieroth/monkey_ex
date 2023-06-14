defmodule MonkeyEx.Evaluator do
  alias MonkeyEx.Ast
  alias MonkeyEx.Object
  require Logger

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

  def eval(%Ast.ReturnStatement{} = ast_node) do
    value = eval(ast_node.return_value)

    cond do
      is_error(value) ->
        value

      true ->
        %Object.ReturnValue{value: value}
    end
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

    cond do
      is_error(left_expression) ->
        left_expression

      is_error(right_expression) ->
        right_expression

      true ->
        eval_infix_expression(left_expression, ast_node.operator, right_expression)
    end
  end

  defp eval_program(program, last_eval \\ nil) do
    do_eval_program(program.statements, last_eval)
  end

  defp do_eval_program([], last_eval), do: last_eval

  defp do_eval_program([statement | rest], _last_eval) do
    value = eval(statement)

    case value do
      %Object.ReturnValue{} -> value.value
      %Object.Error{} -> value
      _ -> do_eval_program(rest, value)
    end
  end

  defp eval_infix_expression(%Object.Integer{} = left, operator, %Object.Integer{} = right) do
    eval_integer_infix_expression(left, operator, right)
  end

  # defp eval_infix_expression(%Object.String{} = left, operator, %Object.String{}) do
  #   eval_string_infix_expression(left, operator, right)
  # end

  defp eval_infix_expression(left, "==", right),
    do: %Object.Boolean{value: left.value == right.value}

  defp eval_infix_expression(left, "!=", right),
    do: %Object.Boolean{value: left.value != right.value}

  defp eval_infix_expression(left, operator, right) do
    left_type = Object.type(left)
    right_type = Object.type(right)

    if left_type != right_type do
      %Object.Error{message: "type mismatch: #{left_type} #{operator} #{right_type}"}
    else
      %Object.Error{message: "unknown operator: #{left_type} #{operator} #{right_type}"}
    end
  end

  defp eval_integer_infix_expression(left, operator, right) do
    case operator do
      "+" ->
        %Object.Integer{value: left.value + right.value}

      "-" ->
        %Object.Integer{value: left.value - right.value}

      "*" ->
        %Object.Integer{value: left.value * right.value}

      "/" ->
        %Object.Integer{value: left.value / right.value}

      ">" ->
        %Object.Boolean{value: left.value > right.value}

      "<" ->
        %Object.Boolean{value: left.value < right.value}

      "==" ->
        %Object.Boolean{value: left.value == right.value}

      "!=" ->
        %Object.Boolean{value: left.value != right.value}

      _ ->
        %Object.Error{
          message: "unknown operator: #{Object.type(left)}#{operator}#{Object.type(right)}"
        }
    end
  end

  defp eval_prefix_expression(operator, right) do
    case operator do
      "!" ->
        eval_bang_operator_expression(right)

      "-" ->
        eval_minus_operator_expression(right)

      _ ->
        %Object.Error{message: "unknown operator: #{operator}#{Object.type(right)}"}
    end
  end

  defp eval_block_statement(block, last_eval \\ nil) do
    do_eval_block_statement(block.statements, last_eval)
  end

  defp do_eval_block_statement([], last_eval), do: last_eval

  defp do_eval_block_statement([statement | rest], _last_eval) do
    value = eval(statement)

    case value do
      %Object.Error{} -> value
      %Object.ReturnValue{} -> value
      _ -> do_eval_block_statement(rest, value)
    end
  end

  @spec eval_if_expression(%Ast.IfExpression{}) :: any()
  defp eval_if_expression(expression) do
    evaluated_condition = eval(expression.condition)

    cond do
      is_error(evaluated_condition) ->
        evaluated_condition

      is_truthy(evaluated_condition) ->
        eval(expression.consequence)

      expression.alternative != nil ->
        eval(expression.alternative)

      true ->
        %Object.Null{}
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
        %Object.Error{message: "unknown operator: -#{Object.type(right)}"}
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

  defp is_error(%Object.Error{}), do: true
  defp is_error(_), do: false
end
