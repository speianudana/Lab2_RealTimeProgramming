## Laboratory 2

### The basic requirements are:
- Process events as soon as they come
- Have 3 groups of workers parsing and averaging the measurements and 3 supervisors, or one, whatever, depends on how you will tackle the publishers part
- Dynamically change the number of actors (up and down) depending on the load
- In case of a special `panic` message, kill the worker actor and then restart it
- Make a message broker that supports multiple topics, subscribing and unsubscribing, no hardcoding
- Develop at least 3 subscribers that will (1) print the results, (2) compute forecast, and (3) be an MQTT adapter.
- The code must be published on Github, otherwise, the lab will not be accepted + please do put it into a container, so I or anyone else can run it locally without much hassle
- Remember the single responsibility principle, in this case - one actor/group of actors per task -> use a different actor for collecting data, creating the forecast, aggregating results, pretty-printing  to console, anything else

### How to start:
For all 3 elixir projects:
```
mix deps.get
iex -S mix
```
For python script(receives data from MQTT adapter):
```
python3 receiveData.py
```

### How it works:

#### 1. Publishers:
1. The start point is  main_application.ex file with the module name Lab2.Application. The Application instance starts 6 processes(actors): 
- MqttClient - publishes the data to broker(using TCP protocol);
- SensorSupervisor - starts dynamically the actors to analyse weather data from all 3 sources;
- Group1(EventSourceWeather module) - receives the stream data from the "http://localhost:4000/iot";
- Group2(EventSourceWeather module) - receives the stream data from the "http://localhost:4000/sensors";
- Group3(EventSourceWeather module) - receives the stream data from the "http://localhost:4000/legacy_sensors";
- LoadData - increases and decreases the number of actors depending on the load, also receives the data from all 3 stream sources(Group1, Group2, Group3);

2. Util modules:
mqtt_util.ex - has the encode_packet method that encodes the message data and topic in a mqtt packet.
```
def encode_packet(data) do
    message = Message.publish("weather sensors", data, 0, 0, 0)
    Packet.encode(message)
  end
```
load_data_util.ex - contains methods for adding actors,delete actors, checking the number of actors for the load.
message_parse_util.ex - calculates the average of two values from the same type of sensor per message.

3. Other modules: 
sensor_event.ex - worker thread that calculates the average and it's  number is increased or decreased depending on the streaming load. Data is sent to Message Broker using MqttClient module.

eventsource_weather.ex - receives sensors stream data and decodes the json xml values from stream. 

4. MQTT modules:
- mqtt_decoder.ex - Provides functions for decoding bytes(binary) to Message structs;
- mqtt_encoder.ex - Provides functions for encoding Message structs to bytes(binary);
- mqtt_message.ex - Provides the structs and constructors for different kinds of message packets in the MQTT protocol;
- mqtt_protocol.ex - Defines Packet protocol and provides implementations for bus Messages;

#### 2. Message Broker module:


#### 3. Subscribers:

1. First start point is mqtt_client.ex with the module name MqttClient.Application. This starts these modules:
- MessageStatus module - joins the sensors data and calculates the average values of the every sensor.
- WeatherPrediction - joins the sensor data and makes a weather forecast;
- MqttAdapter - joins the sensor data and sends them further to the port 7777 encoded as an Mqtt packages. This works as a virtual sensor. 
- MqttClient1, MqttClient2, MqttClient3 - are TCP clients connected to the broker that receive sensor data and send to MessageStatus,WeatherPrediction, MqttAdapter respectivelly.
P.S: MessageStatus,WeatherPrediction, MqttAdapter receive data every 3 seconds.

2. Util modules:
message_parse_util.ex - function for joining the data from all messages for every sensor based on timestamp (in range +-100 miliseconds), function for weather forecast and a function for weather prediction.
mqtt_util.ex - encodes the message packets according to MQTT protocol.


The MQTT protocol  for encoding and decoding packages are the same as in the Publishers module.
