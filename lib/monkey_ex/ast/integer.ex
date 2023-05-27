defmodule MonkeyEx.Ast.IntegerLiteral do
  @moduledoc """
  `MonkeyEx.Ast.IntegerLiteral` is a integer literal.

  Example:

  ```
  let five = 5; // <-- 5 is an integer literal
  ```
  """

  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Node, for: __MODULE__ do
    def token_literal(integer), do: Token.literal(integer.token)

    def node_type(_node), do: :expression

    def string(integer), do: integer.value
  end
end
