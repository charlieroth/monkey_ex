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
    def token_literal(integer) do
      integer.token.literal
    end

    def node_type(_), do: :expression

    def value(integer) do
      integer.value
    end
  end
end
