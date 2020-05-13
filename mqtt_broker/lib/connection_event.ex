defmodule ConnectEvent do
  use GenServer
  alias Mqtt.Protocol.Packet

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, [])
  end

  def init(socket) do
    {:ok, socket}
  end

  def handle_info({:tcp,socket,packet},state) do
    decoded_packet = Poison.encode!(Packet.decode(packet)[:message])
    cond do
      decoded_packet =~ "PUBLISH" ->
        MessageBroadcast.broadcast(decoded_packet)
      decoded_packet =~ "SUBSCRIBE" ->
        MessageBroadcast.subscribe(socket, decoded_packet)
      decoded_packet =~ "UNSUBSCRIBE" ->
        MessageBroadcast.unsubscribe(socket)
      true ->
        IO.inspect "Packet not supported"
    end
    {:noreply, state}
  end

  def handle_info({:tcp_closed,_},state) do
    IO.inspect "Connection has been closed"
    if state[:socket] != nil do
      MessageBroadcast.unsubscribe(state[:socket])
    end
    {:noreply,state}
  end

  def handle_info({:tcp_error,socket,reason},state) do
    IO.inspect socket,label: "Connection closed because #{reason}"
    if state[:socket] != nil do
      MessageBroadcast.unsubscribe(state[:socket])
    end
    {:noreply,state}
  end
end