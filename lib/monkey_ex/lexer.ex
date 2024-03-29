defmodule MonkeyEx.Lexer do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Token

  defguardp is_whitespace(ch) when ch in ~c[ \n\t]
  defguardp is_letter(ch) when ch in ?a..?z or ch in ?A..?Z or ch == ?_
  defguardp is_digit(ch) when ch in ?0..?9
  defguardp is_quote(ch) when ch == ?"

  @spec init(String.t()) :: [Token.t()]
  def init(input) when is_binary(input), do: lex(input, [])

  @spec lex(String.t(), [Token.t()]) :: [Token.t()]
  defp lex(<<>>, tokens), do: [:eof | tokens] |> Enum.reverse()
  defp lex(<<ch::8, rest::binary>>, tokens) when is_whitespace(ch), do: lex(rest, tokens)

  defp lex(input, tokens) do
    {token, rest} = tokenize(input)
    lex(rest, [token | tokens])
  end

  @spec tokenize(String.t()) :: {Token.t(), String.t()}
  defp tokenize(<<"==", rest::binary>>), do: {:equal_equal, rest}
  defp tokenize(<<"!=", rest::binary>>), do: {:not_equal, rest}
  defp tokenize(<<";", rest::binary>>), do: {:semicolon, rest}
  defp tokenize(<<",", rest::binary>>), do: {:comma, rest}
  defp tokenize(<<"(", rest::binary>>), do: {:lparen, rest}
  defp tokenize(<<")", rest::binary>>), do: {:rparen, rest}
  defp tokenize(<<"{", rest::binary>>), do: {:lbrace, rest}
  defp tokenize(<<"}", rest::binary>>), do: {:rbrace, rest}
  defp tokenize(<<"=", rest::binary>>), do: {:assign, rest}
  defp tokenize(<<"+", rest::binary>>), do: {:plus, rest}
  defp tokenize(<<"-", rest::binary>>), do: {:minus, rest}
  defp tokenize(<<"!", rest::binary>>), do: {:bang, rest}
  defp tokenize(<<"/", rest::binary>>), do: {:slash, rest}
  defp tokenize(<<"*", rest::binary>>), do: {:asterisk, rest}
  defp tokenize(<<">", rest::binary>>), do: {:greater_than, rest}
  defp tokenize(<<"<", rest::binary>>), do: {:less_than, rest}
  defp tokenize(<<ch::8, rest::binary>>) when is_quote(ch), do: read_string(rest)
  defp tokenize(<<ch::8, rest::binary>>) when is_letter(ch), do: read_identifier(rest, <<ch>>)
  defp tokenize(<<ch::8, rest::binary>>) when is_digit(ch), do: read_number(rest, <<ch>>)
  defp tokenize(<<ch::8, rest::binary>>), do: {{:illegal, <<ch>>}, rest}

  defp read_string(rest) do
    {string, [_quote | rest]} =
      Enum.split_while(String.split(rest, "", trim: true), &(!is_quote?(&1)))

    {{:string, Enum.join(string, "")}, Enum.join(rest, "")}
  end

  @spec read_identifier(String.t(), iodata()) :: {Token.t(), String.t()}
  defp read_identifier(<<ch::8, rest::binary>>, acc) when is_letter(ch) do
    read_identifier(rest, [acc | <<ch>>])
  end

  defp read_identifier(rest, acc) do
    ident = acc |> IO.iodata_to_binary() |> tokenize_word()
    {ident, rest}
  end

  @spec read_number(String.t(), iodata()) :: {Token.t(), String.t()}
  defp read_number(<<ch::8, rest::binary>>, acc) when is_digit(ch) do
    read_number(rest, [acc | <<ch>>])
  end

  defp read_number(rest, number) do
    number = number |> IO.iodata_to_binary()
    {{:int, number}, rest}
  end

  @spec tokenize_word(String.t()) :: Token.keyword_token() | {:ident, String.t()}
  defp tokenize_word("fn"), do: :fn
  defp tokenize_word("let"), do: :let
  defp tokenize_word("if"), do: :if
  defp tokenize_word("else"), do: :else
  defp tokenize_word("true"), do: true
  defp tokenize_word("false"), do: false
  defp tokenize_word("return"), do: :return
  defp tokenize_word(ident), do: {:ident, ident}

  defp is_quote?(ch), do: ch == "\""
end
