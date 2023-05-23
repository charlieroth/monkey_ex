defmodule MirlangTest do
  use ExUnit.Case
  doctest Mirlang

  test "hello/0 responds with :mir" do
    assert Mirlang.hello() == :mir
  end
end
