defmodule McpsWebWeb.ContextJSON do
  @moduledoc """
  JSON views for the Context Controller.
  """

  @doc """
  Renders a list of contexts.
  """
  def index(%{contexts: contexts}) do
    %{data: for(context <- contexts, do: data(context))}
  end

  @doc """
  Renders a single context.
  """
  def show(%{context: context}) do
    %{data: data(context)}
  end

  @doc """
  Renders context data.
  """
  def data(context) do
    %{
      id: context.id,
      content: context.content,
      metadata: context.metadata,
      version: context.version,
      created_at: format_datetime(context.created_at),
      updated_at: format_datetime(context.updated_at),
      ttl: context.ttl,
      owner_id: context.owner_id,
      tags: context.tags,
      size: MCPS.Core.Context.size(context)
    }
  end

  # Format datetime to ISO8601
  defp format_datetime(nil), do: nil
  defp format_datetime(datetime), do: DateTime.to_iso8601(datetime)
end
