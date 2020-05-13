defmodule MqttClientTest do
  use ExUnit.Case
  doctest MqttClient

  test "greets the world" do
    assert MqttClient.hello() == :world
  end
end
