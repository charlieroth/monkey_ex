defmodule MonkeyEx.Environment do
  @enforce_keys [:store]
  defstruct [:store]

  @spec new :: %MonkeyEx.Environment{}
  def new() do
    %MonkeyEx.Environment{store: %{}}
  end

  @spec get(%MonkeyEx.Environment{}, String.t()) :: any()
  def get(environment, name) do
    Map.get(environment.store, name)
  end

  @spec set(%MonkeyEx.Environment{}, String.t(), any()) :: %MonkeyEx.Environment{}
  def set(environment, name, val) do
    %{environment | store: Map.put(environment.store, name, val)}
  end
end
