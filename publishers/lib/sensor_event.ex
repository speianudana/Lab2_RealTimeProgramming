defmodule SensorEvent do
  use GenServer

  def start_link(actor_id) do
    GenServer.start_link(__MODULE__, [actor_id], name: actor_name(actor_id))
  end

  def process_event(actor_id, message) do
    GenServer.cast(actor_name(actor_id), {:process, message, actor_id})
  end

  def exit(actor_id) do
    GenServer.cast(actor_name(actor_id), {:exit, actor_id})
  end

  def init(actor_id) do
    {:ok, actor_id}
  end

  def handle_cast({:exit, _}, state) do
    DynamicSupervisor.terminate_child(SensorSupervisor, self())
    {:noreply, state}
  end

  def handle_cast({:process, message, _}, state) do
      if  message.data =~ "panic" do
        DynamicSupervisor.terminate_child(SensorSupervisor, self())
      else
        message_result = MessageParseUtil.get_message(message.data)
        MqttClient.publish_message(MqttUtil.encode_packet(Poison.encode!(message_result)))
      end
      {:noreply, state}
  end

  def actor_name(actor_id),
       do: String.to_atom(actor_id)
end
