defmodule Ast.InfixExpression do
  alias Ast.Node

  @enforce_keys [:token, :left, :operator, :right]
  defstruct [:token, :left, :operator, :right]

  defimpl Node, for: __MODULE__ do
    def token_literal(infix_expression), do: infix_expression.token.literal

    def node_type(_node), do: :expression

    def string(infix_expression) do
      left = Node.string(infix_expression.left)
      operator = infix_expression.operator
      right = Node.string(infix_expression.right)
      "#{left} #{operator} #{right}"
    end
  end
end
