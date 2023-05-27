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
    PrefixExpression
    # InfixExpression
  }

  @type statement ::
          %LetStatement{}
          | %ReturnStatement{}
          | %ExpressionStatement{}

  @type expression :: %Identifier{} | %IntegerLiteral{}

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
    parse_program(parser, statements)
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

    parser = next_token(parser)
    parse_program(parser, statements)
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
         {:ok, parser, value} <- parse_expression(parser) do
      identifier = %Identifier{token: ident_token, value: Token.literal(ident_token)}
      parser = skip_semicolon(parser)
      {parser, %LetStatement{token: curr_token, name: identifier, value: value}}
    else
      {:error, %Parser{} = parser} ->
        {parser, nil}

      {:error, parser, nil} ->
        {parser, nil}
    end
  end

  @spec parse_return_statement(%Parser{}) :: {%Parser{}, %ReturnStatement{}}
  defp parse_return_statement(parser) do
    curr_token = parser.current_token

    with parser <- next_token(parser),
         {:ok, parser, return_value} = parse_expression(parser),
         parser <- skip_semiclon(parser) do
      {parser, %ReturnStatement{token: curr_token, return_value: return_value}}
    else
      _ ->
        {parser, nil}
    end
  end

  @spec parse_expression_statement(%Parser{}) :: {%Parser{}, %ExpressionStatement{} | nil}
  defp parse_expression_statement(parser) do
    curr_token = parser.current_token

    with {:ok, parser, expression} <- parse_expression(parser) do
      {
        parser,
        %ExpressionStatement{token: curr_token, expression: expression}
      }
    else
      {:error, parser, nil} ->
        {parser, nil}
    end
  end

  @spec parse_expression(%Parser{}) ::
          {:ok, %Parser{}, expression()} | {:error, %Parser{}, nil}
  defp parse_expression(parser) do
    case prefix_parse_fns(parser.current_token, parser) do
      {parser, nil} ->
        {:error, parser, nil}

      {parser, expression} ->
        # {parser, expression} = check_infix(parser, expression, precedence)
        {:ok, parser, expression}
    end
  end

  # def check_infix(parser, left_expression, precedence) do
  #   next_not_semi = parser.peek_token != :semicolon
  #   lower_precedence = precedence < peek_precedence(parser)
  #   allowed = next_not_semi && lower_precedence

  #   with true <- allowed,
  #        infix_fn <- infix_parse_fns(parser.peek_token),
  #        true <- infix_fn != nil do
  #     parser = parser |> next_token()
  #     {parser, infix} = infix_fn.(parser, left_expression)
  #     check_infix(parser, infix, precedence)
  #   else
  #     _ -> {parser, left_expression}
  #   end
  # end

  @spec prefix_parse_fns(Token.t(), %Parser{}) ::
          {%Parser{}, expression() | nil}
  defp prefix_parse_fns({:ident, _}, parser), do: parse_identifier(parser)
  defp prefix_parse_fns({:int, _}, parser), do: parse_int(parser)
  defp prefix_parse_fns(:bang, parser), do: parse_bang(parser)
  defp prefix_parse_fns(:minus, parser), do: parse_minus(parser)
  defp prefix_parse_fns(_, parser), do: {parser, nil}

  # defp infix_parse_fns(:plus), do: &parse_infix_expression(&1, &2)
  # defp infix_parse_fns(:minus), do: &parse_infix_expression(&1, &2)
  # defp infix_parse_fns(:slash), do: &parse_infix_expression(&1, &2)
  # defp infix_parse_fns(:asterisk), do: &parse_infix_expression(&1, &2)
  # defp infix_parse_fns(_), do: nil

  # defp parse_infix_expression(parser, left_expression) do
  #   curr_token = parser.current_token
  #   operator = Token.literal(parser.current_token)
  #   precedence = curr_precedence(parser)
  #   parser = parser |> next_token()
  #   {_, parser, right_expression} = parse_expression(parser, precedence)

  #   infix_expression = %InfixExpression{
  #     token: curr_token,
  #     left: left_expression,
  #     operator: operator,
  #     right: right_expression
  #   }

  #   {parser, infix_expression}
  # end

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
        msg = "Failed to parse #{number} as integer literal"
        parser = parser |> add_error(msg)
        {parser, nil}

      {value, _} ->
        expression = %IntegerLiteral{token: parser.current_token, value: value}
        {parser, expression}
    end
  end

  @spec parse_bang(%Parser{}) :: {%Parser{}, %PrefixExpression{}}
  defp parse_bang(parser) do
    curr_token = parser.current_token
    bang_operator = Token.literal(curr_token)
    parser = next_token(parser)
    {_, parser, right_expression} = parse_expression(parser)

    {
      parser,
      %PrefixExpression{
        token: curr_token,
        operator: bang_operator,
        right: right_expression
      }
    }
  end

  @spec parse_minus(%Parser{}) :: {%Parser{}, %PrefixExpression{}}
  defp parse_minus(parser) do
    curr_token = parser.current_token
    minus_operator = Token.literal(curr_token)
    parser = next_token(parser)
    {_, parser, right_expression} = parse_expression(parser)

    {
      parser,
      %PrefixExpression{
        token: curr_token,
        operator: minus_operator,
        right: right_expression
      }
    }
  end

  @spec skip_semicolon(%Parser{}) :: %Parser{}
  defp skip_semicolon(%Parser{peek_token: :semicolon} = parser), do: next_token(parser)
  defp skip_semiclon(%Parser{} = parser), do: parser

  @spec next_token(%Parser{}) :: %Parser{}
  defp next_token(%Parser{tokens: []} = parser) do
    %Parser{parser | current_token: parser.peek_token, peek_token: nil}
  end

  defp next_token(%Parser{} = parser) do
    [next_peek_token | rest] = parser.tokens
    %Parser{parser | current_token: parser.peek_token, peek_token: next_peek_token, tokens: rest}
  end

  @spec expect_peek(%Parser{}, atom()) :: {:ok, %Parser{}, Token.t()} | {:error, %Parser{}}
  defp expect_peek(%Parser{peek_token: {:ident, _identifier} = peek_token} = parser, :ident) do
    {:ok, next_token(parser), peek_token}
  end

  defp expect_peek(%Parser{peek_token: peek_token} = parser, :ident) do
    parser = add_error(parser, "Expected token #{inspect(:ident)}, got #{inspect(peek_token)}")
    {:error, parser}
  end

  defp expect_peek(%Parser{peek_token: :assign} = parser, :assign) do
    {:ok, next_token(parser), :assign}
  end

  defp expect_peek(%Parser{peek_token: peek_token} = parser, :assign) do
    parser = add_error(parser, "Expected token #{inspect(:assign)}, got #{inspect(peek_token)}")
    {:error, parser}
  end

  defp add_error(%Parser{errors: errors} = parser, msg),
    do: %Parser{parser | errors: [msg | errors]}

  # defp curr_precedence(parser), do: Map.get(@precedence, parser.current_token, @precedence.lowest)
  # defp peek_precedence(parser), do: Map.get(@precedence, parser.peek_token, @precedence.lowest)
end
