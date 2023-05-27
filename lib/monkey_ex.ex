defmodule MonkeyEx do
  @moduledoc false

  alias MonkeyEx.Parser
  alias MonkeyEx.Lexer

  def run(input) do
    input
    |> Lexer.init()
    |> Parser.from_tokens()
    |> Parser.parse([])
  end
end
