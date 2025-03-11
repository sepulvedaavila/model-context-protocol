defmodule McpsCoreTest do
  use ExUnit.Case
  doctest McpsCore

  test "greets the world" do
    assert McpsCore.hello() == :world
  end
end
