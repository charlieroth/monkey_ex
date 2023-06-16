defmodule MonkeyEx do
  @moduledoc false

  alias MonkeyEx.{Lexer, Parser, Evaluator, Environment}
  require Logger

  def run(input) do
    {parser, program} =
      input
      |> Lexer.init()
      |> Parser.init()
      |> Parser.parse([])

    if not Enum.empty?(parser.errors) do
      Logger.error("Woops! We ran into some monkey business here!")

      error_msgs =
        Enum.map(parser.errors, fn error_msg ->
          "#{error_msg}\n"
        end)

      Logger.error(error_msgs)
    else
      evaluated = Evaluator.eval(program, Environment.new())
      evaluated.value
    end
  end
end
