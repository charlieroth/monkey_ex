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

  def eval(%Ast.StringLiteral{} = ast_node, %Environment{} = env) do
    {%Object.String{value: ast_node.value}, env}
  end

  def eval(%Ast.BooleanLiteral{} = ast_node, %Environment{} = env) do
    {%Object.Boolean{value: ast_node.value}, env}
  end

  def eval(%Ast.FunctionLiteral{} = ast_node, %Environment{} = env) do
    {%Object.Function{parameters: ast_node.parameters, body: ast_node.body, env: env}, env}
  end

  def eval(%Ast.CallExpression{} = ast_node, %Environment{} = env) do
    {function, env} = eval(ast_node.function, env)

    case function do
      %Object.Error{} ->
        {function, env}

      _ ->
        {args, env} = eval_function_args(ast_node.arguments, env)

        if length(args) == 1 && is_error(Enum.at(args, 0)) do
          {Enum.at(args, 0), env}
        else
          {apply_function(function, args), env}
        end
    end
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

  defp do_eval_program([], env, last_eval), do: {last_eval, env}

  defp do_eval_program([statement | rest], env, _last_eval) do
    {value, env} = eval(statement, env)

    case value do
      %Object.ReturnValue{} -> {value.value, env}
      %Object.Error{} -> {value, env}
      _ -> do_eval_program(rest, env, value)
    end
  end

  defp eval_function_args(args, env) do
    {evaluated, env} =
      Enum.reduce_while(args, {[], env}, fn arg, {acc, env} ->
        {value, env} = eval(arg, env)

        case value do
          %Object.Error{} ->
            {:halt, {value, env}}

          _ ->
            {:cont, {[value | acc], env}}
        end
      end)

    {Enum.reverse(evaluated), env}
  end

  defp apply_function(%Object.Function{} = function, args) do
    extended_env = extended_function_env(function, args)
    {value, _env} = eval(function.body, extended_env)
    unwrap(value)
  end

  defp apply_function(function, _args),
    do: %Object.Error{message: "not a function: #{Object.type(function)}"}

  defp extended_function_env(function, args) do
    env = Environment.enclose(function.env)

    function.parameters
    |> Enum.zip(args)
    |> List.foldl(env, fn {identifier, arg}, env ->
      Environment.set(env, identifier.value, arg)
    end)
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
        %Object.Integer{value: round(left.value / right.value)}

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

  defp unwrap(%Object.ReturnValue{} = obj), do: obj.value
  defp unwrap(obj), do: obj

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
