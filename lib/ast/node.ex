defprotocol Ast.Node do
  @moduledoc """
  `Ast.Node` is a protocol that all AST nodes implement.
  """

  @doc "Returns the token literal of the node"
  def token_literal(node)

  @doc "Returns the type of the node"
  def node_type(node)

  @doc "Returns the underlying value of the node"
  def string(node)
end
