defmodule MonkeyEx.Object.Error do
  @moduledoc """
  TODO
  """

  alias MonkeyEx.Object

  @enforce_keys [:message]
  defstruct [:message]

  defimpl Object, for: __MODULE__ do
    def type(_error), do: "error"

    def inspect(error), do: "error: #{error.message}"
  end
end
