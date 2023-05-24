defmodule Ast.ReturnStatement do
  @moduledoc """
  `Ast.ReturnStatement` is a statement that returns a value.

  Example:

  ```
  let x = 5;
  let y = 10;
  return x + y; <-- Returns the sum of x and y
  ```
  """

  alias Ast.Node

  @enforce_keys [:token, :return_value]
  defstruct [:token, :return_value]

  defimpl Node, for: __MODULE__ do
    def token_literal(return_statement) do
      return_statement.token.literal
    end

    def node_type(_), do: :statement

    def value(return_statement) do
      return_statement.return_value
    end
  end
end
