defmodule Dispatcher do
  use GenServer

  def new(subs) do
    GenServer.start_link(__MODULE__, subs)
  end

  def send_message(pid, channel, message) do
    GenServer.call(pid, {:send, channel, message})
  end

  def subscribe(pid, channel, process) do
    GenServer.call(pid, {:sub, channel, process})
  end

  def unsubscribe(pid, channel, process) do
    GenServer.call(pid, {:unsub, channel, process})
  end

  def handle_call({:sub, channel, process}, _from, subs) do
    Subscriptions.subscribe(subs, channel, process)
    {:reply, :ok, subs}
  end

  def handle_call({:unsub, channel, process}, _from, subs) do
    Subscriptions.unsubscribe(subs, channel, process)
    {:reply, :ok, subs}
  end
  
  def handle_call({:send, channel, message}, _from, subs) do
    case Subscriptions.get(subs, channel) do
      nil ->
	{:reply, :empty, subs}
      subscribers ->
	Enum.map(subscribers, fn s -> spawn(fn -> MessageWorker.snd(s, message) end) end)
	{:reply, :ok, subs}
    end
  end

  
end
