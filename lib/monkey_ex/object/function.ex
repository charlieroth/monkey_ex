defmodule MonkeyEx.Object.Function do
  alias MonkeyEx.Object
  alias MonkeyEx.Ast.Node

  @enforce_keys [:parameters, :body, :env]
  defstruct [:parameters, :body, :env]

  defimpl Object, for: __MODULE__ do
    def type(_function), do: "function"

    def inspect(function) do
      params =
        function.parameters
        |> Enum.map(&Node.string/1)
        |> Enum.join(", ")

      body = function.body |> Node.string()

      """
      fn(#{params}) {
      #{body}
      }
      """
    end
  end
end
