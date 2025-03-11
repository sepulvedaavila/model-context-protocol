defmodule MCPS.Management.Cache do
  @moduledoc """
  Cache for contexts to improve performance.
  """

  use GenServer
  require Logger
  alias MCPS.Telemetry.Metrics

  @table_name :mcps_context_cache
  @default_ttl 3600  # 1 hour in seconds

  # Client API

  @doc """
  Starts the cache.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a context from the cache.

  Returns {:ok, context} if found, {:error, :not_found} otherwise.
  """
  def get(id) when is_binary(id) do
    start_time = System.monotonic_time()
    result = case :ets.lookup(@table_name, id) do
      [{^id, context, _expires_at}] ->
        # Record hit
        Metrics.observe([:mcps, :cache, :hit], %{count: 1}, %{cache_name: @table_name})
        {:ok, context}

      [] ->
        # Record miss
        Metrics.observe([:mcps, :cache, :miss], %{count: 1}, %{cache_name: @table_name})
        {:error, :not_found}
    end

    # Record duration
    end_time = System.monotonic_time()
    Metrics.observe([:mcps, :cache, :get], %{duration: end_time - start_time}, %{
      cache_name: @table_name,
      result: elem(result, 0)
    })

    result
  end

  @doc """
  Puts a context in the cache.

  Options:
  - :ttl - Time to live in seconds (default: 1 hour)
  """
  def put(context, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    expires_at = System.os_time(:second) + ttl

    start_time = System.monotonic_time()
    :ets.insert(@table_name, {context.id, context, expires_at})
    end_time = System.monotonic_time()

    # Record metrics
    Metrics.observe([:mcps, :cache, :put], %{duration: end_time - start_time}, %{
      cache_name: @table_name
    })

    # Record size
    size = :ets.info(@table_name, :size)
    Metrics.observe([:mcps, :cache, :size], %{value: size}, %{cache_name: @table_name})

    :ok
  end

  @doc """
  Invalidates a context in the cache.
  """
  def invalidate(id) when is_binary(id) do
    start_time = System.monotonic_time()
    :ets.delete(@table_name, id)
    end_time = System.monotonic_time()

    # Record metrics
    Metrics.observe([:mcps, :cache, :invalidate], %{duration: end_time - start_time}, %{
      cache_name: @table_name
    })

    :ok
  end

  @doc """
  Clears the entire cache.
  """
  def clear do
    start_time = System.monotonic_time()
    :ets.delete_all_objects(@table_name)
    end_time = System.monotonic_time()

    # Record metrics
    Metrics.observe([:mcps, :cache, :clear], %{duration: end_time - start_time}, %{
      cache_name: @table_name
    })

    :ok
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Create ETS table
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true, write_concurrency: true])

    # Start cleanup process
    schedule_cleanup()

    {:ok, %{table: table}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    # Remove expired entries
    start_time = System.monotonic_time()
    now = System.os_time(:second)

    # Find expired entries
    expired = :ets.select(@table_name, [{{:'$1', :'$2', :'$3'}, [{:<, :'$3', now}], [:'$1']}])

    # Delete expired entries
    Enum.each(expired, fn id -> :ets.delete(@table_name, id) end)

    end_time = System.monotonic_time()

    # Record metrics
    Metrics.observe([:mcps, :cache, :cleanup], %{
      duration: end_time - start_time,
      expired_count: length(expired)
    }, %{
      cache_name: @table_name
    })

    # Record size
    size = :ets.info(@table_name, :size)
    Metrics.observe([:mcps, :cache, :size], %{value: size}, %{cache_name: @table_name})

    # Schedule next cleanup
    schedule_cleanup()

    {:noreply, state}
  end

  # Private functions

  defp schedule_cleanup do
    # Run cleanup every minute
    Process.send_after(self(), :cleanup, 60_000)
  end
end
