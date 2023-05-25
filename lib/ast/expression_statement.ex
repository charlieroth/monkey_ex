defmodule Ast.ExpressionStatement do
  alias Ast.Node

  @enforce_keys [:token, :expression]
  defstruct [:token, :expression]

  defimpl Node, for: __MODULE__ do
    def token_literal(expression_statement) do
      expression_statement.token.literal
    end

    def node_type(_node) do
      :statement
    end

    def value(%{expression: nil}) do
      ""
    end

    def value(expression_statement) do
      Node.value(expression_statement.expression)
    end
  end
end
