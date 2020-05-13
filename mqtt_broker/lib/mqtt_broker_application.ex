defmodule MqttBroker.Application do
  use Application

  def start(_type, _args) do
    ip = {127,0,0,1}
    port = 6666
    children = [
      {MessageBroadcast, restart: :permanent},
      %{
        id: ConnectionSupervisor,
        start: {ConnectionSupervisor, :start_link, []}
      },
      %{
        id: MqttBrokerServer,
        start: {MqttBrokerServer, :start_link, [ip, port]}
      }
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
