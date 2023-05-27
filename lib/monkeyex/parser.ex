defmodule MonkeyEx.Parser do
  @enforce_keys [:tokens, :current_token, :peek_token, :errors]
  defstruct [:tokens, :current_token, :peek_token, :errors]

  require Logger

  alias MonkeyEx.Parser
  alias MonkeyEx.Token

  alias MonkeyEx.Ast.{
    Program,
    LetStatement,
    ReturnStatement,
    Identifier,
    IntegerLiteral,
    ExpressionStatement,
    InfixExpression
  }

  @type t :: %{
          tokens: [Token.t()],
          current_token: Token.t(),
          peek_token: Token.t(),
          errors: [String.t()]
        }

  @precedence %{
    lowest: 0,
    # ==
    equals: 1,
    # > or <
    less_greater: 2,
    # +
    sum: 3,
    # *
    product: 4,
    # -X or !X
    prefix: 5,
    # myFunc(X)
    call: 6
  }

  def from_tokens(tokens) do
    [current_token | [peek_token | rest]] = tokens

    %Parser{
      current_token: current_token,
      peek_token: peek_token,
      tokens: rest,
      errors: []
    }
  end

  def parse(parser, statements) do
    parser |> parse_program(statements)
  end

  def parse_program(%Parser{current_token: :eof} = parser, statements) do
    statements = Enum.reverse(statements)
    program = %Program{statements: statements}
    {parser, program}
  end

  def parse_program(%Parser{} = parser, statements) do
    {parser, statement} = parse_statement(parser)

    statements =
      case statement do
        nil -> statements
        s -> [s | statements]
      end

    parser = parser |> next_token()
    parse_program(parser, statements)
  end

  def parse_statement(parser) do
    case parser.current_token.type do
      :let -> parse_let_statement(parser)
      :return -> parse_return_statement(parser)
      _ -> parse_expression_statement(parser)
    end
  end

  def parse_let_statement(parser) do
    curr_token = parser.current_token

    with {:ok, parser, ident_token} <- expect_peek(parser, :ident),
         {:ok, parser, _assign_token} <- expect_peek(parser, :assign),
         parser <- parser |> next_token(),
         {:ok, parser, value} <- parse_expression(parser, @precedence.lowest) do
      identifier = %Identifier{token: ident_token, value: ident_token.literal}
      statement = %LetStatement{token: curr_token, name: identifier, value: value}
      parser = parser |> skip_semicolon()
      {parser, statement}
    else
      {:error, parser, _} -> {parser, nil}
    end
  end

  def parse_return_statement(parser) do
    curr_token = parser.current_token
    parser = parser |> next_token()
    {_, parser, return_value} = parse_expression(parser, @precedence.lowest)
    parser = parser |> skip_semicolon()
    statement = %ReturnStatement{token: curr_token, return_value: return_value}
    {parser, statement}
  end

  def parse_expression_statement(parser) do
    curr_token = parser.current_token
    {_, parser, expression} = parse_expression(parser, @precedence.lowest)

    expression_statement = %ExpressionStatement{
      token: curr_token,
      expression: expression
    }

    {parser, expression_statement}
  end

  def parse_expression(parser, precedence) do
    case prefix_parse_fns(parser.current_token.type, parser) do
      {parser, nil} ->
        {:error, parser, nil}

      {parser, expression} ->
        {parser, expression} = check_infix(parser, expression, precedence)
        {:ok, parser, expression}
    end
  end

  def check_infix(parser, left_expression, precedence) do
    next_not_semi = parser.peek_token.type != :semicolon
    lower_precedence = precedence < peek_precedence(parser)
    allowed = next_not_semi && lower_precedence

    with true <- allowed,
         infix_fn <- infix_parse_fns(parser.peek_token.type),
         true <- infix_fn != nil do
      parser = parser |> next_token()
      {parser, infix} = infix_fn.(parser, left_expression)
      check_infix(parser, infix, precedence)
    else
      _ -> {parser, left_expression}
    end
  end

  def prefix_parse_fns(:ident, parser), do: parse_identifier(parser)
  def prefix_parse_fns(:int, parser), do: parse_int(parser)
  def prefix_parse_fns(_, parser), do: {parser, nil}

  def infix_parse_fns(:plus), do: &parse_infix_expression(&1, &2)
  def infix_parse_fns(:minus), do: &parse_infix_expression(&1, &2)
  def infix_parse_fns(:slash), do: &parse_infix_expression(&1, &2)
  def infix_parse_fns(:asterisk), do: &parse_infix_expression(&1, &2)
  def infix_parse_fns(_), do: nil

  def parse_infix_expression(parser, left_expression) do
    curr_token = parser.curr_token
    operator = parser.curr_token.literal
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

  def parse_identifier(parser) do
    expression = %Identifier{
      token: parser.current_token,
      value: parser.current_token.literal
    }

    {parser, expression}
  end

  def parse_int(parser) do
    number = Integer.parse(parser.current_token.literal)

    case number do
      :error ->
        msg = "Failed to parse #{number} as integer literal"
        parser = parser |> add_error(msg)
        {parser, nil}

      {value, _} ->
        expression = %IntegerLiteral{token: parser.current_token, value: value}
        {parser, expression}
    end
  end

  def skip_semicolon(parser) do
    if parser.peek_token == :semicolon do
      parser |> next_token()
    else
      parser
    end
  end

  def next_token(%Parser{tokens: []} = parser) do
    %Parser{parser | current_token: parser.peek_token, peek_token: nil}
  end

  def next_token(%Parser{} = parser) do
    [next_peek_token | rest] = parser.tokens
    %Parser{parser | current_token: parser.peek_token, peek_token: next_peek_token, tokens: rest}
  end

  def expect_peek(%Parser{peek_token: peek_token} = parser, expected_type) do
    if peek_token.type == expected_type do
      parser = parser |> next_token()
      {:ok, parser, peek_token}
    else
      msg = "Expected token #{inspect(expected_type)}, got #{inspect(peek_token.type)}"
      parser = parser |> add_error(msg)
      {:error, parser, msg}
    end
  end

  def add_error(%Parser{errors: errors} = parser, msg) do
    %Parser{parser | errors: errors ++ [msg]}
  end

  def curr_precedence(parser) do
    Map.get(@precedence, parser.curr_token.type, @precedence.lowest)
  end

  def peek_precedence(parser) do
    Map.get(@precedence, parser.peek_token.type, @precedence.lowest)
  end
end
