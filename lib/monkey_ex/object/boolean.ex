defmodule MonkeyEx.Object.Boolean do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Object

  @enforce_keys [:value]
  defstruct [:value]

  defimpl Object, for: __MODULE__ do
    def type(_boolean), do: "boolean"

    def inspect(boolean), do: Atom.to_string(boolean.value)
  end
end
