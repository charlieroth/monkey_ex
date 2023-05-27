defmodule MonkeyEx.Ast.Identifier do
  @moduledoc """
  `MonkeyEx.Ast.Identifier` is a name given to a variable or function.

  Example:

  ```
  let five = 5; // <-- five is an identifier
  ```
  """

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl MonkeyEx.Ast.Node, for: __MODULE__ do
    def token_literal(identifier), do: identifier.token.literal

    def node_type(_node), do: :expression

    def string(identifier), do: identifier.value
  end
end
