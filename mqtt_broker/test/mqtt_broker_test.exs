defmodule MqttBrokerTest do
  use ExUnit.Case
  doctest MqttBroker

  test "greets the world" do
    assert MqttBroker.hello() == :world
  end
end
