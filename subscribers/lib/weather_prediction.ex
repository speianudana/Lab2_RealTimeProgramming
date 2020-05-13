defmodule WeatherPrediction do
  use GenServer
  @name WeatherPrediction

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: @name])
  end

  def save_record(package) do
    GenServer.cast(@name, {:save_record, package})
  end

  def init(state) do
    schedule_post(state)
    {:ok, []}
  end

  def handle_cast({:save_record, package}, cache) do
    message = Poison.decode!(Poison.decode!(package)["message"])
    {:noreply, cache++[message]}
  end

  defp schedule_post(state) do
    IO.inspect("Client 2 - Collecting data...")
    Process.send_after(self(),:postSchedule, 3000)
    {:noreply,state}
  end

  def handle_info(:postSchedule, messages) do
    if length(messages) != 0 do
      data_results = MessageParseUtil.join_data(messages)
      weather_forecast = for message <- data_results do
        MessageParseUtil.forecast(message)
      end
      IO.inspect("Client 2 - Most common forecast #{MessageParseUtil.prediction(weather_forecast)}")
    end
    schedule_post([])
    {:noreply,[]}
  end
end