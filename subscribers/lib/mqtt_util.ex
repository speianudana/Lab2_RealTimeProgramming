defmodule MqttUtil do
  alias Mqtt.Message
  alias Mqtt.Protocol.Packet

  def encode_packet_subscribe(packet_id, topic) do
    message = Message.subscribe(packet_id, topic, [1])
    Packet.encode(message)
  end

  def encode_packet(data) do
    message = Message.publish("weather sensors", data, 0, 0, 0)
    Packet.encode(message)
  end
end