defmodule MCPS.Core.Context do
  @moduledoc """
  The core Context data structure.
  """

  @type metadata :: %{optional(String.t()) => any()}

  @type t :: %__MODULE__{
    id: String.t(),
    content: map(),
    metadata: metadata(),
    version: integer(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    ttl: integer() | nil,
    owner_id: String.t(),
    tags: [String.t()]
  }

  defstruct [
    :id,
    :content,
    :metadata,
    :version,
    :created_at,
    :updated_at,
    :ttl,
    :owner_id,
    tags: []
  ]

  @doc """
  Validates a context struct.

  Returns :ok if valid, {:error, reason} otherwise.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(context) do
    cond do
      is_nil(context.id) or context.id == "" ->
        {:error, "ID is required"}

      is_nil(context.content) ->
        {:error, "Content is required"}

      is_nil(context.version) or context.version < 1 ->
        {:error, "Version must be a positive integer"}

      is_nil(context.owner_id) or context.owner_id == "" ->
        {:error, "Owner ID is required"}

      true ->
        :ok
    end
  end

  @doc """
  Calculates the size of a context in bytes.
  """
  @spec size(t()) :: integer()
  def size(context) do
    # Convert to JSON and get byte size as an approximation
    context
    |> Jason.encode!()
    |> byte_size()
  end
end
