defmodule MonkeyEx.Ast.StringLiteral do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Ast.Node

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Node, for: __MODULE__ do
    def token_literal(string_literal), do: string_literal.token.literal

    def node_type(_node), do: :expression

    def string(string_literal), do: string_literal.token.literal
  end
end
