defmodule MonkeyEx.Parser do
  @enforce_keys [:tokens, :current_token, :peek_token, :errors]
  defstruct [:tokens, :current_token, :peek_token, :errors]

  require Logger

  alias MonkeyEx.{Parser, Token}

  alias MonkeyEx.Ast.{
    Program,
    Identifier,
    IntegerLiteral,
    BooleanLiteral,
    FunctionLiteral,
    LetStatement,
    ReturnStatement,
    BlockStatement,
    ExpressionStatement,
    PrefixExpression,
    InfixExpression,
    IfExpression,
    CallExpression
  }

  @type statement ::
          %LetStatement{}
          | %ReturnStatement{}
          | %ExpressionStatement{}
          | %BlockStatement{}

  @type expression ::
          %Identifier{}
          | %IntegerLiteral{}
          | %BooleanLiteral{}
          | %FunctionLiteral{}

  @type t :: %{
          tokens: [Token.t()],
          current_token: Token.t(),
          peek_token: Token.t(),
          errors: [String.t()]
        }

  @precedence %{
    lowest: 0,
    # ==
    equal_equal: 1,
    # !=
    not_equal: 1,
    # > or <
    greater_than: 2,
    less_than: 2,
    # +
    plus: 3,
    # -
    minus: 3,
    # /
    slash: 4,
    # *
    asterisk: 4,
    # -X or !X
    prefix: 5,
    # (
    lparen: 6,
    # myFunc(X)
    call: 6
  }

  @spec init([Token.t()]) :: %Parser{}
  def init(tokens) do
    [current_token | [peek_token | rest]] = tokens

    %Parser{
      current_token: current_token,
      peek_token: peek_token,
      tokens: rest,
      errors: []
    }
  end

  @spec parse(%Parser{}, [statement()]) :: {%Parser{}, %Program{}}
  def parse(parser, statements) do
    {parser, program} = parse_program(parser, statements)
    {parser, program}
  end

  @spec parse_program(%Parser{}, [statement()]) :: {%Parser{}, %Program{}}
  defp parse_program(%Parser{current_token: :eof} = parser, statements) do
    {
      parser,
      %Program{
        statements: Enum.reverse(statements)
      }
    }
  end

  defp parse_program(parser, statements) do
    {parser, statement} = parse_statement(parser.current_token, parser)

    statements =
      case statement do
        nil -> statements
        s -> [s | statements]
      end

    if not Enum.empty?(parser.errors) do
      {parser, %Program{statements: Enum.reverse(statements)}}
    else
      parser = next_token(parser)
      parse_program(parser, statements)
    end
  end

  @spec parse_statement(Token.t(), %Parser{}) :: {%Parser{}, statement() | nil}
  defp parse_statement(:let, parser), do: parse_let_statement(parser)
  defp parse_statement(:return, parser), do: parse_return_statement(parser)
  defp parse_statement(_, parser), do: parse_expression_statement(parser)

  @spec parse_let_statement(%Parser{}) :: {%Parser{}, %LetStatement{} | nil}
  defp parse_let_statement(parser) do
    curr_token = parser.current_token

    with {:ok, parser, ident_token} <- expect_peek(parser, :ident),
         {:ok, parser, _assign_token} <- expect_peek(parser, :assign),
         parser <- next_token(parser),
         {:ok, parser, value} <- parse_expression(parser, @precedence.lowest) do
      parser = skip_semicolon(parser)

      {
        parser,
        %LetStatement{
          token: curr_token,
          name: %Identifier{token: ident_token, value: Token.literal(ident_token)},
          value: value
        }
      }
    else
      {:error, parser, nil} ->
        {parser, nil}
    end
  end

  @spec parse_return_statement(%Parser{}) :: {%Parser{}, %ReturnStatement{}}
  defp parse_return_statement(parser) do
    curr_token = parser.current_token
    parser = next_token(parser)
    {_, parser, return_value} = parse_expression(parser, @precedence.lowest)
    parser = skip_semicolon(parser)
    {parser, %ReturnStatement{token: curr_token, return_value: return_value}}
  end

  @spec parse_expression_statement(%Parser{}) :: {%Parser{}, %ExpressionStatement{}}
  defp parse_expression_statement(parser) do
    curr_token = parser.current_token
    {_, parser, expression} = parse_expression(parser, @precedence.lowest)

    {
      skip_semicolon(parser),
      %ExpressionStatement{token: curr_token, expression: expression}
    }
  end

  @spec parse_expression(%Parser{}, any()) ::
          {:ok, %Parser{}, expression()} | {:error, %Parser{}, nil}
  defp parse_expression(parser, precedence) do
    case prefix_parse_fns(parser.current_token, parser) do
      {parser, nil} ->
        {:error, parser, nil}

      {parser, expression} ->
        {parser, expression} = check_infix(parser, expression, precedence)
        {:ok, parser, expression}
    end
  end

  @spec prefix_parse_fns(Token.t(), %Parser{}) ::
          {%Parser{}, expression() | nil}
  defp prefix_parse_fns({:ident, _}, parser), do: parse_identifier(parser)
  defp prefix_parse_fns({:int, _}, parser), do: parse_int(parser)
  defp prefix_parse_fns(true, parser), do: parse_boolean(parser)
  defp prefix_parse_fns(false, parser), do: parse_boolean(parser)
  defp prefix_parse_fns(:lparen, parser), do: parse_grouped_expression(parser)
  defp prefix_parse_fns(:if, parser), do: parse_if_expression(parser)
  defp prefix_parse_fns(:fn, parser), do: parse_function_literal(parser)
  defp prefix_parse_fns(:bang, parser), do: parse_prefix_expression(parser)
  defp prefix_parse_fns(:minus, parser), do: parse_prefix_expression(parser)

  defp prefix_parse_fns(_, parser) do
    {add_error(parser, "No prefix function for token: #{parser.current_token}"), nil}
  end

  @spec check_infix(%Parser{}, expression(), any()) :: {%Parser{}, expression()}
  def check_infix(parser, left_expression, precedence) do
    with true <- parser.peek_token != :semicolon,
         true <- precedence < peek_precedence(parser),
         infix_fn <- infix_parse_fns(parser.peek_token),
         true <- infix_fn != nil do
      parser = next_token(parser)
      {parser, infix_expression} = infix_fn.(parser, left_expression)
      check_infix(parser, infix_expression, precedence)
    else
      _ ->
        {parser, left_expression}
    end
  end

  @spec infix_parse_fns(Token.t()) :: fun() | nil
  defp infix_parse_fns(:plus), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:minus), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:slash), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:greater_than), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:less_than), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:asterisk), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:not_equal), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:equal_equal), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fns(:lparen), do: &parse_call_expression(&1, &2)
  defp infix_parse_fns(_), do: nil

  @spec parse_infix_expression(%Parser{}, any()) :: {%Parser{}, %InfixExpression{}}
  defp parse_infix_expression(parser, left_expression) do
    curr_token = parser.current_token
    operator = Token.literal(parser.current_token)
    precedence = curr_precedence(parser)
    parser = parser |> next_token()
    {_, parser, right_expression} = parse_expression(parser, precedence)

    infix_expression = %InfixExpression{
      token: curr_token,
      left: left_expression,
      operator: operator,
      right: right_expression
    }

    {parser, infix_expression}
  end

  @spec parse_identifier(%Parser{}) :: {%Parser{}, %Identifier{}}
  defp parse_identifier(parser) do
    {
      parser,
      %Identifier{
        token: parser.current_token,
        value: Token.literal(parser.current_token)
      }
    }
  end

  @spec parse_int(%Parser{}) :: {%Parser{}, %IntegerLiteral{}}
  defp parse_int(parser) do
    number =
      parser.current_token
      |> Token.literal()
      |> Integer.parse()

    case number do
      :error ->
        {add_error(parser, "Failed to parse #{number} as integer literal"), nil}

      {value, _} ->
        {parser, %IntegerLiteral{token: parser.current_token, value: value}}
    end
  end

  @spec parse_boolean(%Parser{}) :: {%Parser{}, %BooleanLiteral{}}
  defp parse_boolean(parser) do
    {
      parser,
      %BooleanLiteral{
        token: parser.current_token,
        value: parser.current_token
      }
    }
  end

  @spec parse_grouped_expression(%Parser{}) :: {%Parser{}, expression()}
  defp parse_grouped_expression(parser) do
    parser = next_token(parser)
    {_, parser, inner_expression} = parse_expression(parser, @precedence.lowest)

    case expect_peek(parser, :rparen) do
      {:error, parser, nil} ->
        {parser, nil}

      {:ok, parser, _} ->
        {parser, inner_expression}
    end
  end

  @spec parse_if_expression(%Parser{}) :: {%Parser{}, %IfExpression{} | nil}
  defp parse_if_expression(parser) do
    curr_token = parser.current_token

    with {:ok, parser, _} <- expect_peek(parser, :lparen),
         parser <- next_token(parser),
         {:ok, parser, condition_expression} <- parse_expression(parser, @precedence.lowest),
         {:ok, parser, _} <- expect_peek(parser, :rparen),
         {:ok, parser, _} <- expect_peek(parser, :lbrace) do
      {parser, consequence_expression} = parse_block_statement(parser)
      {parser, alternative_expression} = parse_if_statement(parser)

      {parser,
       %IfExpression{
         token: curr_token,
         condition: condition_expression,
         consequence: consequence_expression,
         alternative: alternative_expression
       }}
    else
      {:error, parser, nil} ->
        {parser, nil}
    end
  end

  @spec parse_block_statement(%Parser{}, [statement()]) :: {%Parser{}, %BlockStatement{}}
  defp parse_block_statement(parser, statements \\ []) do
    curr_token = parser.current_token
    parser = next_token(parser)
    do_parse_block_statement(parser, curr_token, statements)
  end

  @spec do_parse_block_statement(%Parser{}, Token.t(), [statement()]) ::
          {%Parser{}, %BlockStatement{}}
  defp do_parse_block_statement(%Parser{current_token: :rbrace} = parser, token, statements) do
    {
      parser,
      %BlockStatement{
        token: token,
        statements: Enum.reverse(statements)
      }
    }
  end

  defp do_parse_block_statement(%Parser{} = parser, token, statements) do
    {parser, statement} = parse_statement(token, parser)

    statements =
      case statement do
        nil -> statements
        statement -> [statement | statements]
      end

    parser = next_token(parser)
    do_parse_block_statement(parser, parser.current_token, statements)
  end

  @spec parse_if_statement(%Parser{}) :: {%Parser{}, %BlockStatement{} | nil}
  defp parse_if_statement(%Parser{peek_token: :else} = parser) do
    parser = next_token(parser)

    case expect_peek(parser, :lbrace) do
      {:error, parser, nil} ->
        {parser, nil}

      {:ok, parser, _} ->
        parse_block_statement(parser)
    end
  end

  defp parse_if_statement(parser), do: {parser, nil}

  @spec parse_function_literal(%Parser{}) :: {%Parser{}, %FunctionLiteral{} | nil}
  defp parse_function_literal(parser) do
    curr_token = parser.current_token

    with {:ok, parser, _} <- expect_peek(parser, :lparen),
         {parser, parameters} <- parse_function_params(parser),
         {:ok, parser, _} <- expect_peek(parser, :lbrace) do
      {parser, body} = parse_block_statement(parser)

      {
        parser,
        %FunctionLiteral{token: curr_token, parameters: Enum.reverse(parameters), body: body}
      }
    else
      _ ->
        {parser, nil}
    end
  end

  @spec parse_function_params(%Parser{}, [%Identifier{}]) :: {%Parser{}, [%Identifier{}]}
  defp parse_function_params(parser, identifiers \\ []) do
    do_parse_function_params(parser, identifiers)
  end

  @spec do_parse_function_params(%Parser{}, [%Identifier{}]) :: {%Parser{}, [%Identifier{}]}
  defp do_parse_function_params(%Parser{peek_token: :rparen} = parser, [] = identifiers) do
    {next_token(parser), identifiers}
  end

  defp do_parse_function_params(parser, identifiers) do
    parser = next_token(parser)

    identifiers = [
      %Identifier{token: parser.current_token, value: Token.literal(parser.current_token)}
      | identifiers
    ]

    # TODO(charlieroth): Figure out how to do this without nested case
    case parser.peek_token do
      :comma ->
        parser = next_token(parser)
        do_parse_function_params(parser, identifiers)

      _ ->
        case expect_peek(parser, :rparen) do
          {:ok, parser, _} ->
            {parser, identifiers}

          {:error, parser, nil} ->
            {parser, nil}
        end
    end
  end

  @spec parse_call_expression(%Parser{}, %FunctionLiteral{}) :: {%Parser{}, %CallExpression{}}
  defp parse_call_expression(parser, func) do
    curr_token = parser.current_token
    {parser, arguments} = parse_call_expression_args(parser)

    {
      parser,
      %CallExpression{
        token: curr_token,
        function: func,
        arguments: Enum.reverse(arguments)
      }
    }
  end

  @spec parse_call_expression_args(%Parser{}, [expression()]) :: {%Parser{}, [expression()]}
  defp parse_call_expression_args(parser, arguments \\ []) do
    do_parse_call_expression_args(parser, arguments)
  end

  @spec do_parse_call_expression_args(%Parser{}, [expression()]) :: {%Parser{}, [expression()]}
  defp do_parse_call_expression_args(%Parser{peek_token: :rparen} = parser, [] = arguments) do
    {next_token(parser), arguments}
  end

  defp do_parse_call_expression_args(parser, arguments) do
    parser = next_token(parser)
    {_, parser, argument} = parse_expression(parser, @precedence.lowest)
    arguments = [argument | arguments]

    # TODO(charlieroth): Figure out how to do this without nested case
    case parser.peek_token do
      :comma ->
        parser = next_token(parser)
        do_parse_call_expression_args(parser, arguments)

      _ ->
        case expect_peek(parser, :rparen) do
          {:ok, parser, _peek_token} ->
            {parser, arguments}

          {:error, parser, nil} ->
            {parser, nil}
        end
    end
  end

  @spec parse_prefix_expression(%Parser{}) :: {%Parser{}, %PrefixExpression{}}
  defp parse_prefix_expression(parser) do
    curr_token = parser.current_token
    operator = Token.literal(curr_token)
    parser = next_token(parser)
    {_, parser, right_expression} = parse_expression(parser, @precedence.prefix)

    {
      parser,
      %PrefixExpression{
        token: curr_token,
        operator: operator,
        right: right_expression
      }
    }
  end

  @spec skip_semicolon(%Parser{}) :: %Parser{}
  defp skip_semicolon(%Parser{peek_token: :semicolon} = parser), do: next_token(parser)
  defp skip_semicolon(%Parser{} = parser), do: parser

  @spec next_token(%Parser{}) :: %Parser{}
  defp next_token(%Parser{tokens: []} = parser) do
    %Parser{parser | current_token: parser.peek_token, peek_token: nil}
  end

  defp next_token(%Parser{} = parser) do
    [next_peek_token | rest] = parser.tokens
    %Parser{parser | current_token: parser.peek_token, peek_token: next_peek_token, tokens: rest}
  end

  @spec expect_peek(%Parser{}, Token.t()) ::
          {:ok, %Parser{}, Token.t()} | {:error, %Parser{}, nil}
  defp expect_peek(%Parser{peek_token: {:ident, _identifier} = peek_token} = parser, :ident) do
    {:ok, next_token(parser), peek_token}
  end

  defp expect_peek(%Parser{peek_token: peek_token} = parser, expected_token)
       when peek_token == expected_token do
    {:ok, next_token(parser), peek_token}
  end

  defp expect_peek(%Parser{peek_token: peek_token} = parser, expected_token) do
    {:error,
     add_error(parser, "Expected token #{inspect(expected_token)}, got #{inspect(peek_token)}"),
     nil}
  end

  @spec add_error(%Parser{}, String.t()) :: %Parser{}
  defp add_error(%Parser{errors: errors} = parser, msg),
    do: %Parser{parser | errors: [msg | errors]}

  @spec curr_precedence(%Parser{}) :: integer()
  defp curr_precedence(parser), do: Map.get(@precedence, parser.current_token, @precedence.lowest)

  @spec peek_precedence(%Parser{}) :: integer()
  defp peek_precedence(parser), do: Map.get(@precedence, parser.peek_token, @precedence.lowest)
end
