defmodule MqttBrokerServer do
  use GenServer

  def start_link(ip, port) do
    GenServer.start_link(__MODULE__,[ip,port],[])
  end

  def init [ip,port] do
    {:ok,listen_socket}= :gen_tcp.listen(port,[:binary,{:packet, 0},{:active,true},{:ip,ip}])
    loop_acceptor(listen_socket, ip, port)
    {:ok, %{ip: ip,port: port}}
  end

  def loop_acceptor(listen_socket, ip, port) do
    {:ok,socket } = :gen_tcp.accept listen_socket
    {:ok, pid} = ConnectionSupervisor.start_child(%{ip: ip,port: port,socket: socket})
    :gen_tcp.controlling_process(socket, pid) # TCP messages would be delivered to the given process id(pid)
    loop_acceptor(listen_socket, ip, port)
  end
end