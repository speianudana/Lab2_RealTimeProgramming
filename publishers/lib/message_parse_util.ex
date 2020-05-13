defmodule MessageParseUtil do
  def get_message(message) do
    data = Poison.decode!(message)
    athm_pressure = if message =~ "atmo_pressure" do
      (data["message"]["atmo_pressure_sensor_1"] + data["message"]["atmo_pressure_sensor_2"])/2
    end
    humidity = if message =~ "humidity" do
      (data["message"]["humidity_sensor_1"] + data["message"]["humidity_sensor_2"])/2
    end
    wind_speed = if message =~ "wind_speed" do
      (data["message"]["wind_speed_sensor_1"] + data["message"]["wind_speed_sensor_2"])/2
    end
    light = if message =~ "light_sensor" do
      (data["message"]["light_sensor_1"] + data["message"]["light_sensor_2"])/2
    end
    temperature = if message =~ "temperature_sensor" do
      (data["message"]["temperature_sensor_1"] + data["message"]["temperature_sensor_2"])/2
    end
    unix_timestamp_100us = data["message"]["unix_timestamp_100us"]
    message = %{"athm_pressure" => athm_pressure, "humidity" => humidity, "wind_speed" => wind_speed, "light" => light, "temperature" => temperature, "unix_timestamp_100us" => unix_timestamp_100us}
    remove_empty= for {k, v} <- message, v != nil, do: %{k => v}
    Enum.reduce(remove_empty, fn x, y ->
      Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1 end)
    end)
  end
end