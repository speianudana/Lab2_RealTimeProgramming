defmodule MessageParseUtil do

  def join_data(messages) do
    data_results = for message <- messages do
      time = message["unix_timestamp_100us"]
      same_data = Enum.filter(messages,
        fn(message) -> (message["unix_timestamp_100us"] == time || (message["unix_timestamp_100us"] <= time+100
        && message["unix_timestamp_100us"] >= time-100)) end)

      if length(same_data) > 1 do

        temperature = for data <- same_data do data["temperature"] end
        temperature = Enum.filter(temperature, & !is_nil(&1))
        temperature = if(length(temperature)>0) do  Enum.reduce(temperature, fn (value, sum) -> sum + value end)/length(temperature) end

        humidity = for data <- same_data do  data["humidity"] end
        humidity = Enum.filter(humidity, & !is_nil(&1))
        humidity = if(length(humidity)>0) do Enum.reduce(humidity, fn (value, sum) -> sum + value end)/length(humidity) end

        athm_pressure = for data <- same_data do  data["athm_pressure"] end
        athm_pressure = Enum.filter(athm_pressure, & !is_nil(&1))
        athm_pressure = if(length(athm_pressure)>0) do Enum.reduce(athm_pressure, fn (value, sum) -> sum + value end)/length(athm_pressure) end

        wind_speed = for data <- same_data do  data["wind_speed"] end
        wind_speed = Enum.filter(wind_speed, & !is_nil(&1))
        wind_speed = if(length(wind_speed)>0) do Enum.reduce(wind_speed, fn (value, sum) -> sum + value end)/length(wind_speed) end

        light = for data <- same_data do  data["wind_speed"] end
        light = Enum.filter(light, & !is_nil(&1))
        light = if(length(light)>0) do Enum.reduce(light, fn (value, sum) -> sum + value end)/length(light) end

        message = %{"athm_pressure" => athm_pressure, "humidity" => humidity, "wind_speed" => wind_speed, "light" => light, "temperature" => temperature, "unix_timestamp_100us" => time}
        remove_empty= for {k, v} <- message, v != nil, do: %{k => v}
        Enum.reduce(remove_empty, fn x, y ->
          Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1 end)
        end)
      else
        message
      end
    end
  end

  def forecast(message) do
    temperature = message["temperature"]
    atmo_pressure = message["atmo_pressure"]
    wind_speed = message["wind_speed"]
    light = message["light"]
    humidity = message["humidity"]
    cond do
      temperature < -2 && light < 128 && atmo_pressure < 720 -> "SNOW"
      temperature < -2 && light > 128 && atmo_pressure < 680 -> "WET_SNOW"
      temperature < -8 -> "SNOW"
      temperature < -15 && wind_speed > 45 -> "BLIZZARD"
      temperature > 0 && atmo_pressure < 710 && humidity > 70 && wind_speed < 20 -> "SLIGHT_RAIN"
      temperature > 0 && atmo_pressure < 690 && humidity > 70 && wind_speed > 20 -> "HEAVY_RAIN"
      temperature > 30 && atmo_pressure < 770 && humidity > 80 && light > 192 -> "HOT"
      temperature > 30 && atmo_pressure < 770 && humidity > 50 && light > 192 && wind_speed > 35 -> "CONVECTION_OVEN"
      temperature > 25 && atmo_pressure < 750 && humidity > 70 && light < 192 && wind_speed < 10 -> "WARM"
      temperature > 25 && atmo_pressure < 750 && humidity > 70 && light < 192 && wind_speed > 10 -> "SLIGHT_BREEZE"
      light < 128 -> "CLOUDY"
      temperature > 30 && atmo_pressure < 660 && humidity > 85 && wind_speed > 45 -> "MONSOON"
      true -> "JUST_A_NORMAL_DAY"
    end
  end

  def prediction(list) do
    gb = Enum.group_by(list, &(&1))
    max = Enum.map(gb, fn {_,val} -> length(val) end) |> Enum.max
    for {key,val} <- gb, length(val)==max, do: key
  end

end