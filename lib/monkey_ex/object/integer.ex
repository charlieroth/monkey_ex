defmodule MonkeyEx.Object.Integer do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Object

  @enforce_keys [:value]
  defstruct [:value]

  defimpl Object, for: __MODULE__ do
    def type(_integer), do: "integer"

    def inspect(integer), do: Integer.to_string(integer.value)
  end
end
