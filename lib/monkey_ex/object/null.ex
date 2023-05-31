defmodule MonkeyEx.Object.Null do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Object

  defstruct value: nil

  defimpl Object, for: __MODULE__ do
    def type(_null), do: "null"

    def inspect(_null), do: "null"
  end
end
