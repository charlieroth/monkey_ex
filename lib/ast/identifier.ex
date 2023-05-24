defmodule Ast.Identifier do
  @moduledoc """
  `Ast.Identifier` is a name given to a variable or function.

  Example:

  ```
  let five = 5; // <-- five is an identifier
  ```
  """

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Ast.Node, for: __MODULE__ do
    def token_literal(identifier) do
      identifier.token.literal
    end

    def node_type(_), do: :expression

    def value(identifier) do
      identifier.value
    end
  end
end
