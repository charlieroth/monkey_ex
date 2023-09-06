defmodule MonkeyEx.Object.String do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Object

  @enforce_keys [:value]
  defstruct [:value]

  defimpl Object, for: __MODULE__ do
    def type(_string), do: "string"

    def inspect(string), do: Object.inspect(string.value)
  end
end
