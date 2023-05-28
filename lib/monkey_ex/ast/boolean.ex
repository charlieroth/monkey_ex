defmodule MonkeyEx.Ast.BooleanLiteral do
  @moduledoc """
  `MonkeyEx.Ast.BooleanLiteral` is a boolean literal.

  Example:

  ```
  false;
  true;
  3 > 5 == false;
  3 < 5 == true;
  ```
  """

  alias MonkeyEx.Ast.Node
  alias MonkeyEx.Token

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Node, for: __MODULE__ do
    def token_literal(boolean_literal_expression) do
      Token.literal(boolean_literal_expression.token)
    end

    def node_type(_node), do: :expression

    def string(boolean_literal_expression) do
      if boolean_literal_expression.token == true do
        "true"
      else
        "false"
      end
    end
  end
end
