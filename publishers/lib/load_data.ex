defmodule LoadData do
  use GenServer

  def start_link(actor_count) do
    GenServer.start_link(__MODULE__, actor_count, name: __MODULE__)
  end

  def send_event(pid, event) do
    GenServer.cast(pid, {:send_event, event})
  end

  def init(actor_count) do
    event_count = 0
    actor_id = 0
    actors = 1..actor_count |>
    Enum.map(fn id ->
      actor = LoadDataUtil.get_actor_id(id)
      SensorSupervisor.start_child(actor)
      actor
    end)|> List.to_tuple
    Process.send_after(self(), :check_events, 300)
    {:ok, {actors, actor_id, event_count}}
  end

  def handle_cast({:send_event, event}, state) do
    actors = elem(state, 0)
    actor_id = LoadDataUtil.generate_actor_count(state)
    elem(actors, actor_id-1) |> SensorEvent.process_event(event)
    event_count = elem(state, 2) + 1
    {:noreply, {actors, actor_id, event_count}}
  end

  def handle_info(:check_events, state) do
    {actors, actor_id} = LoadDataUtil.check_actors_state(state)
    Process.send_after(self(), :check_events, 300)
    {:noreply, {actors, actor_id, 0}}
  end
end
