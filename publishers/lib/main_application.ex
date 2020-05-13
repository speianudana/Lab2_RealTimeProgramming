defmodule Lab2.Application do
  use Application

  def start(_type, _args) do
    ip = {127,0,0,1}
    port = 6666
    children = [
      %{
        id: MqttClient,
        start: {MqttClient, :start_link, [ip, port]}
      },
      %{
        id: SensorSupervisor,
        start: {SensorSupervisor, :start_link, []}
      },
      %{
        id: Group1,
        start: {EventSourceWeather, :new, ["http://localhost:4000/iot"]},
        restart: :permanent
      },
      %{
        id: Group2,
        start: {EventSourceWeather, :new, ["http://localhost:4000/sensors"]},
        restart: :permanent
      },
      %{
        id: Group3,
        start: {EventSourceWeather, :new, ["http://localhost:4000/legacy_sensors"]},
        restart: :permanent
      },
      %{
        id: LoadData,
        start: {LoadData, :start_link, [3]},
      },
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end

