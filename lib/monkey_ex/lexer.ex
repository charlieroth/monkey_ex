defmodule MonkeyEx.Lexer do
  @moduledoc false
  alias MonkeyEx.Token

  defguardp is_whitespace(ch) when ch in ~c[ \n\t]
  defguardp is_letter(ch) when ch in ?a..?z or ch in ?A..?Z or ch == ?_
  defguardp is_digit(ch) when ch in ?0..?9

  @spec init(String.t()) :: [Token.t()]
  def init(input) when is_binary(input), do: lex(input, [])

  @spec lex(String.t(), [Token.t()]) :: [Token.t()]
  defp lex(<<>>, tokens), do: [:eof | tokens] |> Enum.reverse()

  # Ignore whitespace
  defp lex(<<ch::8, rest::binary>>, tokens) when is_whitespace(ch) do
    lex(rest, tokens)
  end

  # Recursively tokenize/lex the input string
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
  defp tokenize(<<"return", rest::binary>>), do: {:return, rest}
  defp tokenize(<<"fn", rest::binary>>), do: {:fn, rest}
  defp tokenize(<<"let", rest::binary>>), do: {:let, rest}
  defp tokenize(<<"if", rest::binary>>), do: {:if, rest}
  defp tokenize(<<"else", rest::binary>>), do: {:else, rest}
  defp tokenize(<<"true", rest::binary>>), do: {true, rest}
  defp tokenize(<<"false", rest::binary>>), do: {false, rest}
  defp tokenize(<<ch::8, _::binary>> = input) when is_letter(ch), do: read_identifier(input)
  defp tokenize(<<ch::8, _::binary>> = input) when is_digit(ch), do: read_number(input)
  defp tokenize(<<ch::8, rest::binary>>), do: {{:illegal, <<ch>>}, rest}

  @spec read_identifier(String.t(), iodata()) :: {Token.t(), String.t()}
  defp read_identifier(input, acc \\ "")

  defp read_identifier(<<ch::8, rest::binary>>, acc) when is_letter(ch) do
    read_identifier(rest, [acc | <<ch>>])
  end

  defp read_identifier(rest, identifier) do
    {{:ident, IO.iodata_to_binary(identifier)}, rest}
  end

  @spec read_number(String.t(), iodata()) :: {Token.t(), String.t()}
  defp read_number(input, acc \\ "")

  defp read_number(<<ch::8, rest::binary>>, acc) when is_digit(ch) do
    read_number(rest, [acc | <<ch>>])
  end

  defp read_number(rest, number) do
    {{:int, IO.iodata_to_binary(number)}, rest}
  end
end
