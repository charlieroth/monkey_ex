defmodule MonkeyEx.Ast.ExpressionStatement do
  alias MonkeyEx.Ast.Node

  @enforce_keys [:token, :expression]
  defstruct [:token, :expression]

  defimpl Node, for: __MODULE__ do
    def token_literal(expression_statement), do: expression_statement.token.literal

    def node_type(_node), do: :statement

    def string(%{expression: nil}), do: ""

    def string(expression_statement), do: Node.string(expression_statement.expression)
  end
end
