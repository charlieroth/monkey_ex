defmodule Ast.Program do
  @moduledoc """
  `Ast.Program` is the root node of the AST (Abstract Syntax Tree).
  """

  @enforce_keys [:statements]
  defstruct [:statements]

  @type t :: %{
    statements: list(any())
  }
end
