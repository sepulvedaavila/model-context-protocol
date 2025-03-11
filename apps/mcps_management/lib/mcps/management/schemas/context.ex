defmodule MCPS.Management.Schemas.Context do
  @moduledoc """
  Ecto schema for contexts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "contexts" do
    field :content, :map
    field :metadata, :map, default: %{}
    field :version, :integer, default: 1
    field :ttl, :integer
    field :owner_id, :string
    field :tags, {:array, :string}, default: []

    timestamps()

    has_many :versions, MCPS.Management.Schemas.ContextVersion, foreign_key: :context_id
  end

  @doc """
  Changeset for creating a context.
  """
  def changeset(context, attrs) do
    context
    |> cast(attrs, [:id, :content, :metadata, :version, :ttl, :owner_id, :tags])
    |> validate_required([:id, :content, :version, :owner_id])
  end

  @doc """
  Converts a schema to a Context struct.
  """
  def to_context(schema) do
    %MCPS.Core.Context{
      id: schema.id,
      content: schema.content,
      metadata: schema.metadata,
      version: schema.version,
      created_at: schema.inserted_at,
      updated_at: schema.updated_at,
      ttl: schema.ttl,
      owner_id: schema.owner_id,
      tags: schema.tags
    }
  end

  @doc """
  Converts a Context struct to a changeset.
  """
  def from_context(context) do
    attrs = %{
      id: context.id,
      content: context.content,
      metadata: context.metadata,
      version: context.version,
      ttl: context.ttl,
      owner_id: context.owner_id,
      tags: context.tags
    }

    changeset(%__MODULE__{}, attrs)
  end
end
