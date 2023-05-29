defmodule MonkeyEx.Ast.FunctionLiteral do
  @moduledoc """
  `MonkeyEx.Ast.FunctionLiteral` represents a function in Monkey Lang

  Example:

  ```
  fn(x, y) {
    return x + y;
  }

  fn(x, y) { x + y; }

  let myFunc = fn(x, y) { return x + y; }
  ```
  """

  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :parameters, :body]
  defstruct [:token, :parameters, :body]

  defimpl Node, for: __MODULE__ do
    def token_literal(function_literal) do
      Token.literal(function_literal.token)
    end

    def node_type(_node), do: :expression

    def string(function_literal) do
      params =
        function_literal.parameters
        |> Enum.map(&Node.string/1)
        |> Enum.join(", ")

      [
        Node.token_literal(function_literal),
        "(",
        params,
        ") ",
        Node.string(function_literal.body)
      ]
      |> Enum.join("")
    end
  end
end
