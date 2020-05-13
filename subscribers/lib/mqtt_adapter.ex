defmodule MqttAdapter do
  use GenServer
  @name MqttAdapter

  def start_link(ip, port) do
    GenServer.start_link(__MODULE__,[ip,port], name: @name)
  end

  def init [ip,port] do
    opts = [:binary, active: true]
    get_connection(ip, port, opts, nil, :ok)
  end

  def save_record(package) do
    GenServer.cast(@name, {:save_record, package})
  end

  def handle_cast({:save_record, package}, state) do
    message = Poison.decode!(Poison.decode!(package)["message"])
    if (state[:messages]==nil) do
      {:noreply, Map.put(state, :messages, [message])}
    else
      {:noreply, Map.put(state, :messages, Enum.concat(state[:messages], [message]))}
    end
  end

  def handle_info({:tcp_closed,_},state) do
    IO.inspect "Connection has been closed"
    schedule_post(state)
    {:noreply,state}
  end

  def handle_info({:tcp_error, socket,reason},state) do
    IO.inspect socket,label: "Connection closed because to #{reason}"
    schedule_post(state)
    {:noreply,state}
  end

  defp schedule_post(state) do
    IO.inspect("Client 3 - MQTT adapter sending data...")
    socket = state[:socket]
    messages = state[:messages]
    if (socket !=nil && messages != nil) do
      data_results = MessageParseUtil.join_data(messages)
      for message<-data_results do
        :gen_tcp.send(socket, MqttUtil.encode_packet(Poison.encode!(message)))
      end
    end
    Process.send_after(self(),:postSchedule, 3000)
    {:noreply,Map.delete(state, :messages)}
  end

  def handle_info(:postSchedule, state) do
    opts = [:binary, active: true]
    ip = state[:ip]
    port = state[:port]
    messages = state[:messages]
    get_connection(ip, port, opts, messages, :noreply)
  end

  def get_connection(ip, port, opts, messages, reply) do
    case :gen_tcp.connect(ip, port, opts) do
      {:ok, socket} ->
        schedule_post(%{ip: ip,port: port, messages: messages, socket: socket})
        {reply, %{ip: ip,port: port, messages: messages, socket: socket}}
      {:error, _} ->
        schedule_post(%{ip: ip,port: port, messages: messages, socket: nil})
        {reply, %{ip: ip,port: port, messages: messages, socket: nil}}
      true ->  {reply, %{ip: ip,port: port, messages: messages, socket: nil}}
    end
  end
end