defmodule Mirlang do
  @moduledoc """
  Mirlang module is the entry point for the Mirlang interpreter.
  """

  alias Mirlang.Parser
  alias Mirlang.Lexer

  def run(input) do
    input
    |> Lexer.lex()
    |> Parser.from_tokens()
    |> Parser.parse([])
  end
end
