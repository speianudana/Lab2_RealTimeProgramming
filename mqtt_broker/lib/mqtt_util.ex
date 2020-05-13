defmodule MqttUtil do
  alias Mqtt.Message
  alias Mqtt.Protocol.Packet

  def encode_packet(topic, data) do
    message = Message.publish(topic, data, 0, 0, 0)
    Packet.encode(message)
  end
end