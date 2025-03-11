defmodule McpsManagementTest do
  use ExUnit.Case
  doctest McpsManagement

  test "greets the world" do
    assert McpsManagement.hello() == :world
  end
end
