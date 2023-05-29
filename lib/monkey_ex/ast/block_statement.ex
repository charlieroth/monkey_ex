defmodule MonkeyEx.Ast.BlockStatement do
  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :statements]
  defstruct [:token, :statements]

  defimpl Node, for: __MODULE__ do
    def token_literal(block_statement), do: Token.literal(block_statement.token)

    def node_type(_node), do: :statement

    def string(block_statement) do
      block_statement.statements
      |> Enum.map(&Node.string/1)
      |> Enum.join("")
    end
  end
end
