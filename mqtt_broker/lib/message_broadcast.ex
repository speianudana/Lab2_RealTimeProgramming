defmodule MessageBroadcast do
  use GenServer
  @name MessageBroadcast

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: @name])
  end

  def broadcast(message) do
    GenServer.cast(@name, {:broadcast_message, message})
  end

  def unsubscribe(message) do
    GenServer.cast(@name, {:unsubscribe, message})
  end

  def subscribe(socket, message) do
    GenServer.cast(@name, {:subscribe, socket, message})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:broadcast_message, message}, cache) do
    if cache != nil do
      for {socket, cache_package} <- cache do
        cache_topic = Poison.decode!(cache_package)["topics"]
        server_topic = Poison.decode!(message)["topic"]
        if (Enum.member?(cache_topic, server_topic)) do
          decoded_message = Poison.decode!(message)["message"]
          :gen_tcp.send(socket, MqttUtil.encode_packet(server_topic, decoded_message))
        end
      end
    end
    {:noreply,cache}
  end

  def handle_cast({:unsubscribe, socket}, cache) do
    if cache != nil do
      for {cache_socket, _} <- cache do
        if (cache_socket==socket) do
          IO.inspect(cache_socket, label: "Unsubscribe client")
          {:noreply, Map.delete(cache, socket)}
        end
      end
    end
    {:noreply,cache}
  end

  def handle_cast({:subscribe, socket, client_package}, cache) do
    updated_cache = Map.put(cache, socket, client_package)
    IO.inspect(socket, label: "Connected a client")
    {:noreply, updated_cache}
  end
end