defmodule Mirlang.Parser do
  @enforce_keys [:current_token, :peek_token, :tokens]
  defstruct [:current_token, :peek_token, :tokens]


  require Logger

  alias Mirlang.Parser
  alias Token
  alias Ast.{
    Program,
    LetStatement,
    Identifier,
    IntegerLiteral
  }


  @type t :: %{
    current_token: Token.t(),
    peek_token: Token.t(),
    tokens: list(Token.t())
  }

  def from_tokens(tokens) do
    [current_token | [peek_token | rest]] = tokens
    %Parser{
      current_token: current_token,
      peek_token: peek_token,
      tokens: rest
    }
  end

  def parse(parser, statements) do
    parse_program(parser, statements)
  end

  def parse_program(%Parser{current_token: %Token{type: :eof}} = parser, statements) do
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
      _ -> {parser, nil}
    end
  end

  def parse_let_statement(parser) do
    curr_token = parser.current_token
    with {:ok, parser, ident_token} <- expect_peek(parser, :ident),
         {:ok, parser, _assign_token} <- expect_peek(parser, :assign),
         parser <- parser |> next_token(),
         {:ok, parser, value} <- parse_expression(parser) do
    identifier = %Identifier{token: ident_token, value: ident_token.literal}
    statement = %LetStatement{token: curr_token, name: identifier, value: value}
    parser = parser |> skip_semicolon()
    {parser, statement}
         else
           {:error, parser, _} -> {parser, nil}
         end
  end

  def parse_expression(parser) do
    case do_parse_expression(parser.current_token.type, parser) do
      {parser, nil} -> {:error, parser, nil}
      {parser, expression} -> {:ok, parser, expression}
    end
  end

  def do_parse_expression(:ident, parser), do: parse_identifier(parser)
  def do_parse_expression(:int, parser), do: parse_int(parser)
  def do_parse_expression(_, parser), do: {parser, nil}

  def parse_identifier(parser) do
    expression = %Identifier{token: parser.current_token, value: parser.current_token.literal}
    {parser, expression}
  end

  def parse_int(parser) do
    number = Integer.parse(parser.current_token.literal)
    case number do
      :error -> {:error, parser, nil}
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
    %Parser{parser |
      current_token: parser.peek_token,
      peek_token: nil
    }
  end

  def next_token(%Parser{} = parser) do
    [next_peek_token | rest] = parser.tokens
    %Parser{parser |
      current_token: parser.peek_token,
      peek_token: next_peek_token,
      tokens: rest
    }
  end

  def expect_peek(%Parser{peek_token: peek_token} = parser, expected_type) do
    if peek_token.type == expected_type do
      parser = parser |> next_token()
      {:ok, parser, peek_token}
    else
      {:error, parser, "Expected token #{inspect(expected_type)}, got #{inspect(peek_token.type)}"}
    end
  end
end
