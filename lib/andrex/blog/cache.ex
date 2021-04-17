defmodule Andrex.Blog.Cache do
  require Logger
  use GenServer

  @name __MODULE__
  @ets_options [:set, :named_table, {:read_concurrency, true}]

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(@name, [], name: @name)

    Logger.info("📓 Started Andrex.Blog.Cache 📓", pid: pid)

    {:ok, pid}
  end

  def init(_) do
    ets = :ets.new(@name, @ets_options)

    {:ok, ets: ets}
  end

  def handle_call(:get_ets, _from, [ets: ets] = state) do
    # ets = :ets.whereis(@name)

    {:reply, ets, state}
  end

  def handle_call({:insert, key, value}, _from, [ets: ets] = state) do

    result = :ets.insert(ets, {key, value})

    {:reply, result, state}
  end

  def handle_call({:get, key}, _from, [ets: ets] = state) do

    :ets.lookup(ets, key)
    |> case do
      [] ->
        {:reply, nil, state}

      [{^key, value}] ->
        {:reply, value, state}
    end
  end

  def get_ets do
    GenServer.call(__MODULE__, :get_ets)
  end

  def insert(key, value) do
    Logger.debug("Inserting #{inspect(key)}, value: #{inspect(value)}")

    GenServer.call(__MODULE__, {:insert, key, value})
  end

  def get(key) do
    value = GenServer.call(__MODULE__, {:get, key})
    Logger.debug("Fetched #{inspect(key)}, got: #{inspect(value)}")

    value
  end
end
