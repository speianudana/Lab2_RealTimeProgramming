defmodule ConnectionSupervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(socket) do
    children = %{
      id: ConnectEvent,
      start: {ConnectEvent, :start_link, [socket]},
      restart: :permanent
    }
    DynamicSupervisor.start_child(__MODULE__,children)
  end
end
