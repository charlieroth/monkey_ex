defmodule MonkeyEx.Ast.InfixExpression do
  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :left, :operator, :right]
  defstruct [:token, :left, :operator, :right]

  defimpl Node, for: __MODULE__ do
    def token_literal(infix_expression) do
      Token.literal(infix_expression.token)
    end

    def node_type(_node), do: :expression

    def string(infix_expression) do
      left = Node.string(infix_expression.left)
      operator = infix_expression.operator
      right = Node.string(infix_expression.right)
      "(#{left} #{operator} #{right})"
    end
  end
end
