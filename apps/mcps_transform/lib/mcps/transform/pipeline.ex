defmodule MCPS.Transform.Pipeline do
  @moduledoc """
  Handles the execution of transformation pipelines.
  """

  alias MCPS.Core.Context
  alias MCPS.Telemetry.Metrics

  @type transformer :: {module(), keyword()}

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    description: String.t() | nil,
    transformers: [transformer()],
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    owner_id: String.t(),
    active: boolean()
  }

  defstruct [
    :id,
    :name,
    :description,
    :transformers,
    :created_at,
    :updated_at,
    :owner_id,
    active: true
  ]

  @doc """
  Applies a pipeline to a context.

  Returns {:ok, transformed_context} on success.
  Returns {:error, reason} on failure.
  """
  @spec apply(t(), Context.t()) :: {:ok, Context.t()} | {:error, term()}
  def apply(pipeline, context) do
    start_time = System.monotonic_time()

    # Apply each transformer in sequence
    result = Enum.reduce_while(pipeline.transformers, {:ok, context}, fn {transformer_module, options}, {:ok, current_context} ->
      case apply_transformer(transformer_module, current_context, options) do
        {:ok, transformed} ->
          {:cont, {:ok, transformed}}

        {:error, reason} = error ->
          {:halt, error}
      end
    end)

    # Record telemetry
    end_time = System.monotonic_time()
    Metrics.observe([:mcps, :transform, :pipeline, :apply], %{
      duration: end_time - start_time
    }, %{
      pipeline_id: pipeline.id,
      pipeline_name: pipeline.name,
      transformer_count: length(pipeline.transformers),
      result: elem(result, 0)
    })

    result
  end

  @doc """
  Validates a pipeline.

  Returns :ok if valid, {:error, reason} otherwise.
  """
  @spec validate(t()) :: :ok | {:error, term()}
  def validate(pipeline) do
    cond do
      is_nil(pipeline.id) or pipeline.id == "" ->
        {:error, "ID is required"}

      is_nil(pipeline.name) or pipeline.name == "" ->
        {:error, "Name is required"}

      is_nil(pipeline.transformers) or pipeline.transformers == [] ->
        {:error, "Pipeline must have at least one transformer"}

      length(pipeline.transformers) > max_pipeline_steps() ->
        {:error, "Pipeline exceeds maximum number of steps (#{max_pipeline_steps()})"}

      true ->
        # Validate each transformer
        transformer_errors =
          Enum.reduce_while(pipeline.transformers, [], fn {module, options}, errors ->
            case validate_transformer(module, options) do
              :ok ->
                {:cont, errors}

              {:error, reason} ->
                {:halt, [{module, reason} | errors]}
            end
          end)

        if transformer_errors == [] do
          :ok
        else
          {:error, "Invalid transformers: #{inspect(transformer_errors)}"}
        end
    end
  end

  # Private functions

  defp apply_transformer(module, context, options) do
    start_time = System.monotonic_time()

    # Validate options first
    with :ok <- validate_transformer(module, options),
         # Then apply the transformer
         {:ok, transformed} <- module.transform(context, options) do

      # Record telemetry
      end_time = System.monotonic_time()
      Metrics.observe([:mcps, :transform, :transformer, :apply], %{
        duration: end_time - start_time
      }, %{
        transformer: module,
        context_id: context.id,
        result: :success
      })

      {:ok, transformed}
    else
      {:error, reason} = error ->
        # Record telemetry for failures
        end_time = System.monotonic_time()
        Metrics.observe([:mcps, :transform, :transformer, :apply], %{
          duration: end_time - start_time
        }, %{
          transformer: module,
          context_id: context.id,
          result: :error,
          reason: inspect(reason)
        })

        error
    end
  end

  defp validate_transformer(module, options) do
    if function_exported?(module, :validate_options, 1) do
      module.validate_options(options)
    else
      :ok
    end
  end

  defp max_pipeline_steps do
    Application.get_env(:mcps_transform, :max_pipeline_steps, 20)
  end
end
