defmodule MonkeyEx.Ast.CallExpression do
  @moduledoc """
  `MonkeyEx.Ast.CallExpression` represents an function call expression

  Example:

  ```
  add(2, 3)

  add(2 + 2, 3 * 3 * 3)

  fn(x, y) { x + y; }(2, 3)

  callFunctions(2, 3, fn(x, y) { x + y; });
  ```
  """

  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :function, :arguments]
  defstruct [:token, :function, :arguments]

  defimpl Node, for: __MODULE__ do
    def token_literal(call_expression) do
      Token.literal(call_expression.token)
    end

    def node_type(_node), do: :expression

    def string(call_expression) do
      args =
        call_expression.arguments
        |> Enum.map(&Node.string/1)
        |> Enum.join(", ")

      [
        Node.string(call_expression.function),
        "(",
        args,
        ")"
      ]
      |> Enum.join("")
    end
  end
end
