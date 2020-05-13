defmodule MqttClient3 do
  use GenServer
  alias Mqtt.Protocol.Packet
  @name MqttClient3

  def start_link(ip, port) do
    GenServer.start_link(__MODULE__,[ip,port], name: @name)
  end

  def init [ip,port] do
    opts = [:binary, active: true]
    get_connection(ip, port, opts, :ok)
  end

  def handle_info({:tcp,_,packet},state) do
    decoded_packet = Poison.encode!(Packet.decode(packet)[:message])
    cond do
      decoded_packet =~ "PUBLISH" ->
        MqttAdapter.save_record(decoded_packet)
      true -> IO.inspect "Packet not supported"
    end
    {:noreply,state}
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
    IO.inspect("Client 3 - Checking network status...")
    Process.send_after(self(),:postSchedule, 5000)
    {:noreply,state}
  end

  def handle_info(:postSchedule, state) do
    opts = [:binary, active: true]
    ip = state[:ip]
    port = state[:port]
    get_connection(ip, port, opts, :noreply)
  end

  def get_connection(ip, port, opts, reply) do
    case :gen_tcp.connect(ip, port, opts) do
      {:ok, socket} ->
        :gen_tcp.send(socket, MqttUtil.encode_packet_subscribe(3, ["weather sensors"]))
        {reply, %{ip: ip,port: port,socket: socket}}
      {:error, _} ->
        schedule_post(%{ip: ip,port: port, socket: nil})
        {reply, %{ip: ip,port: port, socket: nil}}
      true ->  {reply, %{ip: ip,port: port, socket: nil}}
    end
  end
end