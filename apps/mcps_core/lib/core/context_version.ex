defmodule MCPS.Core.ContextVersion do
  @moduledoc """
  Represents a specific version of a context.
  """

  @type t :: %__MODULE__{
    id: String.t(),
    context_id: String.t(),
    version: integer(),
    content: map(),
    metadata: map(),
    created_at: DateTime.t(),
    created_by: String.t(),
    change_description: String.t() | nil
  }

  defstruct [
    :id,
    :context_id,
    :version,
    :content,
    :metadata,
    :created_at,
    :created_by,
    :change_description
  ]

  @doc """
  Validates a context version struct.

  Returns :ok if valid, {:error, reason} otherwise.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(version) do
    cond do
      is_nil(version.id) or version.id == "" ->
        {:error, "ID is required"}

      is_nil(version.context_id) or version.context_id == "" ->
        {:error, "Context ID is required"}

      is_nil(version.version) or version.version < 1 ->
        {:error, "Version must be a positive integer"}

      is_nil(version.content) ->
        {:error, "Content is required"}

      true ->
        :ok
    end
  end
end
