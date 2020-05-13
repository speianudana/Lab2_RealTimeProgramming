defmodule MqttClient.Application do
  use Application

  def start(_type, _args) do
    ip = {127,0,0,1}
    port = 6666
    adapter_port = 7777
    children = [
      {MessageStatus, restart: :permanent}, #calculates the average
      {WeatherPrediction, restart: :permanent}, # weather prediction - per message
      %{
        id: MqttAdapter,
        start: {MqttAdapter, :start_link, [ip, adapter_port]}
      },
      %{
        id: MqttClient1,
        start: {MqttClient1, :start_link, [ip, port]}
      },
      %{
        id: MqttClient2,
        start: {MqttClient2, :start_link, [ip, port]}
      },
      %{
        id: MqttClient3,
        start: {MqttClient3, :start_link, [ip, port]}
      }
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
