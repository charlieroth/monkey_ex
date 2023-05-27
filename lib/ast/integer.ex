defmodule Ast.IntegerLiteral do
  @moduledoc """
  `Ast.IntegerLiteral` is a integer literal.

  Example:

  ```
  let five = 5; // <-- 5 is an integer literal
  ```
  """

  alias Ast.Node

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Node, for: __MODULE__ do
    def token_literal(integer), do: integer.token.literal

    def node_type(_node), do: :expression

    def string(integer), do: integer.value
  end
end
