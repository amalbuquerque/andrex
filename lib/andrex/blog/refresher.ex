defmodule Andrex.Blog.Refresher do
  require Logger
  use GenServer

  @name __MODULE__

  def start_link(callbacks) do
    {:ok, pid} = GenServer.start_link(@name, callbacks, name: @name)

    Logger.info("📓 Started Andrex.Blog.Refresher 📓Callbacks: #{inspect(callbacks)}", pid: pid)

    {:ok, pid}
  end

  @impl true
  def init(callbacks) do
    schedule_callbacks(callbacks)

    {:ok, []}
  end

  @impl true
  def handle_info({:callback, {module, function, args} = callback}, state) do
    Logger.debug("Calling callback: #{inspect(callback)}")

    Kernel.apply(module, function, args)

    {:noreply, state}
  end

  defp schedule_callbacks([]), do: :nop

  defp schedule_callbacks([callback | rest]) do
    Process.send_after(self(), {:callback, callback}, :timer.seconds(5))

    schedule_callbacks(rest)
  end

  defp schedule_callbacks(callback) when is_tuple(callback) do
    Process.send_after(self(), {:callback, callback}, :timer.seconds(5))
  end
end
