defmodule MCPS.Telemetry.Metrics do
  @moduledoc """
  Handles telemetry metrics collection and reporting.
  """

  require Logger

  @doc """
  Records a telemetry event.

  ## Parameters
  - event_name: List representing the event name (e.g., [:mcps, :context, :create])
  - measurements: Map of measured values (e.g., %{duration: 123})
  - metadata: Map of event metadata (e.g., %{result: :success})
  """
  def observe(event_name, measurements, metadata \\ %{}) do
    :telemetry.execute(event_name, measurements, metadata)
  end

  @doc """
  Attaches a handler to a telemetry event.
  """
  def attach_handler(handler_id, event_patterns, handler_function, config) do
    :telemetry.attach(handler_id, event_patterns, handler_function, config)
  end

  @doc """
  Returns telemetry metrics definitions for Prometheus.
  """
  def prometheus_metrics do
    [
      # API metrics
      counter("mcps.web.request.count",
        description: "Total number of API requests",
        tags: [:controller, :action, :status]
      ),
      distribution("mcps.web.request.duration",
        description: "API request duration",
        unit: {:native, :millisecond},
        reporter_options: [buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]],
        tags: [:controller, :action]
      ),

      # Context operations
      counter("mcps.context.create.count",
        description: "Total number of contexts created",
        tags: [:result]
      ),
      distribution("mcps.context.create.duration",
        description: "Context creation duration",
        unit: {:native, :millisecond},
        tags: [:result]
      ),
      counter("mcps.context.update.count",
        description: "Total number of context updates",
        tags: [:result]
      ),
      distribution("mcps.context.update.duration",
        description: "Context update duration",
        unit: {:native, :millisecond},
        tags: [:result]
      ),

      # Transformation metrics
      counter("mcps.transform.pipeline.count",
        description: "Total number of pipeline executions",
        tags: [:pipeline_name, :result]
      ),
      distribution("mcps.transform.pipeline.duration",
        description: "Pipeline execution duration",
        unit: {:native, :millisecond},
        tags: [:pipeline_name, :transformer_count, :result]
      ),

      # Cache metrics
      last_value("mcps.cache.size",
        description: "Current cache size",
        tags: [:cache_name]
      ),
      counter("mcps.cache.hit",
        description: "Cache hit count",
        tags: [:cache_name]
      ),
      counter("mcps.cache.miss",
        description: "Cache miss count",
        tags: [:cache_name]
      )
    ]
  end

  # Helper functions for metric types

  defp counter(name, options), do: struct(Telemetry.Metrics.Counter, put_metric_name(options, name))
  defp distribution(name, options), do: struct(Telemetry.Metrics.Distribution, put_metric_name(options, name))
  defp last_value(name, options), do: struct(Telemetry.Metrics.LastValue, put_metric_name(options, name))

  defp put_metric_name(options, name) do
    Keyword.put(options, :name, name)
  end
end
