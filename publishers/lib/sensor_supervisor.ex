defmodule SensorSupervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    children = %{
      id: SensorEvent,
      start: {SensorEvent, :start_link, [name]},
      restart: :permanent
    }

    DynamicSupervisor.start_child(__MODULE__,children)
    name
  end
end
