defmodule MonkeyEx.Ast.LetStatement do
  @moduledoc """
  `MonkeyEx.Ast.LetStatement` is a variable declaration.

  Example:

  ```
  let five = 5;
  let ten = 10;
  ```
  """

  alias MonkeyEx.Ast.Node

  @enforce_keys [:token, :name, :value]
  defstruct [:token, :name, :value]

  defimpl Node, for: __MODULE__ do
    def token_literal(let_statement), do: let_statement.token.literal

    def node_type(_node), do: :statement

    def string(let_statement) do
      output = [
        Node.token_literal(let_statement),
        " ",
        Node.string(let_statement.name),
        " = "
      ]

      output =
        if let_statement.value do
          output ++ [Node.string(let_statement.value)]
        else
          output
        end

      output = output ++ [";"]

      Enum.join(output)
    end
  end
end
