defmodule MonkeyEx.Repl do
  alias MonkeyEx.{Evaluator, Lexer, Parser, Environment, Object}

  def loop(env \\ Environment.new()) do
    {parser, program} =
      ">> "
      |> IO.gets()
      |> Lexer.init()
      |> Parser.init()
      |> Parser.parse([])

    if not Enum.empty?(parser.errors) do
      IO.puts("Woops! We ran into some monkey business here!")

      parser.errors
      |> Enum.map(fn error_msg -> "#{error_msg}\n" end)
      |> IO.puts()
    else
      {evaluated, env} = Evaluator.eval(program, env)
      evaluated |> Object.inspect() |> IO.puts()
      loop(env)
    end
  end
end
