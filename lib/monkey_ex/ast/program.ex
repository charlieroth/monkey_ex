defmodule MonkeyEx.Ast.Program do
  @moduledoc """
  `MonkeyEx.Ast.Program` is the root node of the AST (Abstract Syntax Tree).
  """

  @enforce_keys [:statements]
  defstruct [:statements]

  alias MonkeyEx.Ast.Node

  def token_literal(program) do
    if not Enum.empty?(program.statements) do
      program.statements
      |> List.first()
      |> Node.token_literal()
    else
      ""
    end
  end

  def string(program) do
    program.statements
    |> Enum.map(&Node.string/1)
    |> Enum.join()
  end
end
