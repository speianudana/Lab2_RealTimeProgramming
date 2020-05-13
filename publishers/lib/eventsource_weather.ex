defmodule EventSourceWeather do
  use GenServer
  require Logger

  @spec new(String.t, Keyword.t) :: {:ok, pid}
  def new(url, opts \\ []) do
    parent = opts[:stream_to] || self()
    opts = Keyword.put(opts, :stream_to, parent)
           |> Keyword.put(:url, url)

    GenServer.start(__MODULE__, opts, opts)
  end

  def init(opts \\ []) do
    url = opts[:url]
    parent = opts[:stream_to]

    HTTPoison.get!(url, [], stream_to: self(), recv_timeout: :infinity)
    IO.inspect "Sending data to MQTT broker from source: #{url}"
    {:ok, %{parent: parent, message: %EventsourceEx.Message{}, prev_chunk: nil, url: url}}
  end

  def handle_info(%{chunk: data}, %{parent: parent, message: message, prev_chunk: prev_chunk, url: url}) do
    data = if prev_chunk, do: prev_chunk <> data, else: data
    if String.ends_with?(data, "\n\n") do
      data = String.split(data, "\n\n")
      message = parse_stream(data, parent, message)
      {:noreply, %{parent: parent, message: message, prev_chunk: nil, url: url}}
    else
      {:noreply, %{parent: parent, message: message, prev_chunk: data, url: url}}
    end
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    new(state[:url])
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp parse_stream(["" | data], parent, message) do
    if message.data, do: dispatch(parent, message)
    parse_stream(data, parent, %EventsourceEx.Message{})
  end
  defp parse_stream([line | data], parent, message) do
    message = parse(line, message)
    parse_stream(data, parent, message)
  end
  defp parse_stream([], _, message), do: message
  defp parse_stream(data, _, _), do: raise ArgumentError, message: "Unparseable data: #{data}"

  defp parse(raw_line, message) do
    case raw_line do
      ":" <> _ -> message
      line ->
        splits = String.split(line, ":", parts: 2)
        [field | rest] = splits
        value = Enum.join(rest, "") |> String.replace_prefix(" ", "") # Remove single leading space

        case field do
          "event" -> Map.put(message, :event, value)
          "data" ->
            data = message.data || ""
            Map.put(message, :data, data <> value <> "\n")
          "id" -> Map.put(message, :id, value)
          _ -> message
        end
    end
  end

  defp dispatch(_, message) do
    if  message.data =~ "SensorReadings" do
      data = Poison.decode!(message.data)
      info = data["message"] |> String.replace("    ", "")
      map = XmlToMap.naive_map(info)
      unix_timestamp_100us = map["SensorReadings"]["-unix_timestamp_100us"]
      [humidity_sensor_1 | humidity_sensor_2] = map["SensorReadings"]["#content"]["humidity_percent"]["value"]
      [temperature_sensor_1 | temperature_sensor_2] = map["SensorReadings"]["#content"]["temperature_celsius"]["value"]
      data = "{\"message\": {\"humidity_sensor_1\": #{humidity_sensor_1},\"humidity_sensor_2\": #{humidity_sensor_2},\"temperature_sensor_1\": #{temperature_sensor_1},\"temperature_sensor_2\": #{temperature_sensor_2},\"unix_timestamp_100us\": #{unix_timestamp_100us}}}"
      message = Map.put(message, :data, data)
      LoadData.send_event(LoadData, message)
    else
      message = Map.put(message, :data, message.data |> String.replace_suffix("\n", ""))
      LoadData.send_event(LoadData, message)
    end
    :timer.sleep(25)
  end
end
