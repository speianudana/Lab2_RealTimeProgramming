defmodule MessageStatus do
  use GenServer
  @name MessageStatus

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
    IO.inspect("Client 1 - Collecting data...")
    Process.send_after(self(),:postSchedule, 3000)
    {:noreply,state}
  end

  def handle_info(:postSchedule, messages) do
    if length(messages) != 0 do
      messages = MessageParseUtil.join_data(messages)
      temperature = for message <- messages do
        message["temperature"]
      end
      temperature = Enum.filter(temperature, & !is_nil(&1))
      humidity = for message <- messages do
        message["humidity"]
      end
      humidity = Enum.filter(humidity, & !is_nil(&1))
      athm_pressure = for message <- messages do
        message["athm_pressure"]
      end
      athm_pressure = Enum.filter(athm_pressure, & !is_nil(&1))
      wind_speed = for message <- messages do
        message["wind_speed"]
      end
      wind_speed = Enum.filter(wind_speed, & !is_nil(&1))
      light = for message <- messages do
        message["light"]
      end
      light = Enum.filter(light, & !is_nil(&1))
      avg_temperature = Enum.reduce(temperature, fn (value, sum) -> sum + value end)/length(temperature)
      avg_humidity = Enum.reduce(humidity, fn (value, sum) -> sum + value end)/length(humidity)
      avg_athm_pressure = Enum.reduce(athm_pressure, fn (value, sum) -> sum + value end)/length(athm_pressure)
      avg_wind_speed = Enum.reduce(wind_speed, fn (value, sum) -> sum + value end)/length(wind_speed)
      avg_light = Enum.reduce(light, fn (value, sum) -> sum + value end)/length(light)
      message = %{"athm_pressure" => avg_athm_pressure, "humidity" => avg_humidity, "wind_speed" => avg_wind_speed, "light" => avg_light, "temperature" => avg_temperature}

      IO.inspect("Client 1 - Messages: #{length(messages)}")
      IO.inspect("Client 1 - Average temperature: #{avg_temperature}")
      IO.inspect("Client 1 - Average humidity: #{Enum.reduce(humidity, fn (value, sum) -> sum + value end)/length(humidity)}")
      IO.inspect("Client 1 - Average athm_pressure: #{Enum.reduce(athm_pressure, fn (value, sum) -> sum + value end)/length(athm_pressure)}")
      IO.inspect("Client 1 - Average wind_speed: #{Enum.reduce(wind_speed, fn (value, sum) -> sum + value end)/length(wind_speed)}")
      IO.inspect("Client 1 - Average light: #{Enum.reduce(light, fn (value, sum) -> sum + value end)/length(light)}")
      IO.inspect("Client 1 - Weather prediction by average: #{MessageParseUtil.forecast(message)}")
    end
    schedule_post([])
    {:noreply,[]}
  end
end