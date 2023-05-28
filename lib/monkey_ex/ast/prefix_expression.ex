defmodule MonkeyEx.Ast.PrefixExpression do
  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :operator, :right]
  defstruct [:token, :operator, :right]

  defimpl Node, for: __MODULE__ do
    def token_literal(prefix_expression) do
      Token.literal(prefix_expression)
    end

    def node_type(_node), do: :expression

    def string(infix_expression) do
      operator = infix_expression.operator
      right_expression = Node.string(infix_expression.right)
      "(#{operator}#{right_expression})"
    end
  end
end
