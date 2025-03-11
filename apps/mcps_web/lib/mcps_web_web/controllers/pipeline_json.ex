defmodule McpsWebWeb.PipelineJSON do
  @moduledoc """
  JSON views for the Pipeline Controller.
  """

  @doc """
  Renders a list of pipelines.
  """
  def index(%{pipelines: pipelines}) do
    %{data: for(pipeline <- pipelines, do: data(pipeline))}
  end

  @doc """
  Renders a single pipeline.
  """
  def show(%{pipeline: pipeline}) do
    %{data: data(pipeline)}
  end

  @doc """
  Renders pipeline data.
  """
  def data(pipeline) do
    %{
      id: pipeline.id,
      name: pipeline.name,
      description: pipeline.description,
      transformers: render_transformers(pipeline.transformers),
      created_at: format_datetime(pipeline.created_at),
      updated_at: format_datetime(pipeline.updated_at),
      owner_id: pipeline.owner_id,
      active: pipeline.active
    }
  end

  # Format transformers for JSON
  defp render_transformers(transformers) do
    Enum.map(transformers, fn {module, options} ->
      %{
        module: module_name(module),
        options: options_to_map(options)
      }
    end)
  end

  # Get module name as string
  defp module_name(module) do
    module
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end

  # Convert keyword list to map
  defp options_to_map(options) do
    Enum.into(options, %{})
  end

  # Format datetime to ISO8601
  defp format_datetime(nil), do: nil
  defp format_datetime(datetime), do: DateTime.to_iso8601(datetime)
end
