defmodule MonkeyEx.Object.ReturnValue do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Object

  @enforce_keys [:value]
  defstruct [:value]

  defimpl Object, for: __MODULE__ do
    def type(_return_value), do: "return value"

    def inspect(return_value), do: Object.inspect(return_value.value)
  end
end
