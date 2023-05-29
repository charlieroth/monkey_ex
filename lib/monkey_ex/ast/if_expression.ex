defmodule MonkeyEx.Ast.IfExpression do
  @moduledoc """
  `MonkeyEx.Ast.IfExpression` represents an if/else expression

  Example:

  ```
  if (x > y) {
    return x;
  } else {
    return y;
  }

  if (x > y) {
    return x;
  }

  let foobar = if (x > y) { x } else { y };
  ```
  """

  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :condition, :consequence, :alternative]
  defstruct [:token, :condition, :consequence, :alternative]

  defimpl Node, for: __MODULE__ do
    def token_literal(if_expression), do: Token.literal(if_expression.token)

    def node_type(_node), do: :expression

    def string(if_expression) do
      out = [
        "if ",
        Node.string(if_expression.condition),
        " ",
        Node.string(if_expression.consequence)
      ]

      if if_expression.alternative != nil do
        out = out ++ [" else ", Node.string(if_expression.alternative)]
        Enum.join(out, "")
      else
        Enum.join(out, "")
      end
    end
  end
end
