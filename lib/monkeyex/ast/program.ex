defmodule MonkeyEx.Ast.Program do
  @moduledoc """
  `MonkeyEx.Ast.Program` is the root node of the AST (Abstract Syntax Tree).
  """

  @enforce_keys [:statements]
  defstruct [:statements]

  @type t :: %{
          statements: list(any())
        }

  alias MonkeyEx.Ast.Node

  def string(program) do
    program.statements
    |> Enum.map(&Node.string/1)
    |> Enum.join()
  end
end
