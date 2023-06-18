defmodule MonkeyEx.Environment do
  @enforce_keys [:store]
  defstruct [:store, :outer]

  @spec enclose(%MonkeyEx.Environment{}) :: %MonkeyEx.Environment{}
  def enclose(outer_env) do
    %{outer_env | outer: outer_env}
  end

  @spec new :: %MonkeyEx.Environment{}
  def new() do
    %MonkeyEx.Environment{store: %{}}
  end

  @spec get(%MonkeyEx.Environment{}, String.t()) :: any() | nil
  def get(env, name) do
    value = Map.get(env.store, name)

    if is_nil(value) and env.outer do
      __MODULE__.get(env.outer, name)
    else
      value
    end
  end

  @spec set(%MonkeyEx.Environment{}, String.t(), any()) :: %MonkeyEx.Environment{}
  def set(environment, name, val) do
    %{environment | store: Map.put(environment.store, name, val)}
  end
end
