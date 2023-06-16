defmodule MonkeyEx.Evaluator do
  alias MonkeyEx.{Ast, Object, Environment}
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

  def eval(%Ast.Program{} = ast_node, %Environment{} = env) do
    eval_program(ast_node, env)
  end

  def eval(%Ast.BlockStatement{} = ast_node, %Environment{} = env) do
    eval_block_statement(ast_node, env)
  end

  def eval(%Ast.ExpressionStatement{} = ast_node, %Environment{} = env) do
    eval(ast_node.expression, env)
  end

  def eval(%Ast.ReturnStatement{} = ast_node, %Environment{} = env) do
    {value, env} = eval(ast_node.return_value, env)

    cond do
      is_error(value) ->
        {value, env}

      true ->
        {%Object.ReturnValue{value: value}, env}
    end
  end

  def eval(%Ast.LetStatement{} = ast_node, %Environment{} = env) do
    {value, env} = eval(ast_node.value, env)

    cond do
      is_error(value) ->
        {value, env}

      true ->
        {value, Environment.set(env, ast_node.name.value, value)}
    end
  end

  def eval(%Ast.Identifier{} = ast_node, %Environment{} = env) do
    value = Environment.get(env, ast_node.value)

    cond do
      value -> {value, env}
      true -> {%Object.Error{message: "identifier not found: #{ast_node.value}"}, env}
    end
  end

  def eval(%Ast.IntegerLiteral{} = ast_node, %Environment{} = env) do
    {%Object.Integer{value: ast_node.value}, env}
  end

  def eval(%Ast.BooleanLiteral{} = ast_node, %Environment{} = env) do
    {%Object.Boolean{value: ast_node.value}, env}
  end

  def eval(%Ast.IfExpression{} = ast_node, %Environment{} = env) do
    eval_if_expression(ast_node, env)
  end

  def eval(%Ast.PrefixExpression{} = ast_node, %Environment{} = env) do
    {right_expression, env} = eval(ast_node.right, env)

    cond do
      is_error(right_expression) -> {right_expression, env}
      true -> {eval_prefix_expression(ast_node.operator, right_expression), env}
    end
  end

  def eval(%Ast.InfixExpression{} = ast_node, %Environment{} = env) do
    {left_expression, env} = eval(ast_node.left, env)
    {right_expression, env} = eval(ast_node.right, env)

    cond do
      is_error(left_expression) ->
        {left_expression, env}

      is_error(right_expression) ->
        {right_expression, env}

      true ->
        {eval_infix_expression(left_expression, ast_node.operator, right_expression), env}
    end
  end

  defp eval_program(program, env, last_eval \\ nil) do
    do_eval_program(program.statements, env, last_eval)
  end

  defp do_eval_program([], _env, last_eval), do: last_eval

  defp do_eval_program([statement | rest], env, _last_eval) do
    {value, env} = eval(statement, env)

    case value do
      %Object.ReturnValue{} -> {value.value, env}
      %Object.Error{} -> {value, env}
      _ -> do_eval_program(rest, env, value)
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

  defp eval_block_statement(block, env, last_eval \\ nil) do
    do_eval_block_statement(block.statements, env, last_eval)
  end

  defp do_eval_block_statement([], env, last_eval), do: {last_eval, env}

  defp do_eval_block_statement([statement | rest], env, _last_eval) do
    {value, env} = eval(statement, env)

    case value do
      %Object.Error{} -> {value, env}
      %Object.ReturnValue{} -> {value, env}
      _ -> do_eval_block_statement(rest, env, value)
    end
  end

  @spec eval_if_expression(%Ast.IfExpression{}, %Environment{}) :: any()
  defp eval_if_expression(if_expression, env) do
    {evaluated_condition, env} = eval(if_expression.condition, env)

    cond do
      is_error(evaluated_condition) ->
        {evaluated_condition, env}

      is_truthy(evaluated_condition) ->
        eval(if_expression.consequence, env)

      if_expression.alternative != nil ->
        eval(if_expression.alternative, env)

      true ->
        {%Object.Null{}, env}
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
