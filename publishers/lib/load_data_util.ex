defmodule LoadDataUtil do

  def restart_actors(actors) do
    Enum.map(Tuple.to_list(actors), fn id ->
      SensorSupervisor.start_child(id)
    end) |> List.to_tuple
  end

  def generate_actor_count(state) do
    actor_count = elem(state, 1)
    if actor_count < tuple_size(elem(state, 0)) do actor_count + 1  else  1 end
  end

  def check_actors_state(state) do
    actors = elem(state, 0)
    event_count = elem(state, 2)
    total_actors = tuple_size(actors)
    required_actor_nr = LoadDataUtil.get_number_of_actors(event_count)
    actors = LoadDataUtil.restart_actors(actors)
    actors = cond do
      required_actor_nr > total_actors ->
        LoadDataUtil.add_actor(actors, required_actor_nr, total_actors)
      required_actor_nr < total_actors ->
        LoadDataUtil.delete_actor(actors, required_actor_nr, total_actors)
      true -> actors
    end
    {actors, elem(state, 1)}
  end

  def get_number_of_actors(event_number) do
    cond do
      event_number <= 30 -> 3
      event_number <= 100 -> 10
      event_number <= 200 -> 15
      event_number <= 500 -> 20
      event_number > 1000 -> 30
      true -> 3
    end
  end

  def add_actor(actors, required_actor_nr, actors_count) do
    list_actors = Tuple.to_list(actors)
    new_actors = actors_count+1 .. required_actor_nr |>
      Enum.map(fn id ->
        actor = get_actor_id(id)
        SensorSupervisor.start_child(actor)
      end)
    list_actors ++ new_actors |> List.to_tuple
  end

  def delete_actor(actors, required_actor_nr, actors_count) do
    list_actors = Tuple.to_list(actors)
    required_actor_nr+1 .. actors_count |>
      Enum.map(fn id ->
        actor = get_actor_id(id)
        List.delete(list_actors, actor)
        SensorEvent.exit(actor)
      end)
    Enum.slice(list_actors, 0, required_actor_nr) |> List.to_tuple
  end

  def get_actor_id(id) do
    "actor_#{id}"
  end
end