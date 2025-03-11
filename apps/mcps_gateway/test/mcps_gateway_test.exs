defmodule McpsGatewayTest do
  use ExUnit.Case
  doctest McpsGateway

  test "greets the world" do
    assert McpsGateway.hello() == :world
  end
end
