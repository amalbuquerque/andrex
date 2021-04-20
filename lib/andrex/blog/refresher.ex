defmodule Andrex.Blog.Refresher do
  require Logger
  use GenServer

  @name __MODULE__

  def start_link(callback) do
    {:ok, pid} = GenServer.start_link(@name, callback, name: @name)

    Logger.info("📓 Started Andrex.Blog.Refresher 📓Callback: #{inspect(callback)}", pid: pid)

    {:ok, pid}
  end

  @impl true
  def init(callback) do
    schedule_callback(callback)

    {:ok, []}
  end

  @impl true
  def handle_info({:callback, {module, function, args} = callback}, state) do
    Logger.debug("Calling callback: #{inspect(callback)}")

    Kernel.apply(module, function, args)

    {:noreply, state}
  end

  defp schedule_callback(callback) do
    Process.send_after(self(), {:callback, callback}, :timer.seconds(5))
  end
end
