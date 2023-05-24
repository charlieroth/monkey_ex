defmodule Ast.LetStatement do
  @moduledoc """
  `Ast.LetStatement` is a variable declaration.

  Example:

  ```
  let five = 5;
  let ten = 10;
  ```
  """

  alias Ast.Node

  @enforce_keys [:token, :name, :value]
  defstruct [:token, :name, :value]

  defimpl Node, for: __MODULE__ do
    def token_literal(let_statement) do
      let_statement.token.literal
    end

    def node_type(_), do: :statement

    def value(let_statement) do
      let_statement.value
    end
  end
end
