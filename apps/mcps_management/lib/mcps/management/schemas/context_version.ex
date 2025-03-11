defmodule MCPS.Management.Schemas.ContextVersion do
  @moduledoc """
  Ecto schema for context versions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "context_versions" do
    field :context_id, :string
    field :version, :integer
    field :content, :map
    field :metadata, :map, default: %{}

    timestamps()

    belongs_to :context, MCPS.Management.Schemas.Context,
      foreign_key: :context_id,
      references: :id,
      type: :string,
      define_field: false
  end

  @doc """
  Changeset for creating a context version.
  """
  def changeset(version, attrs) do
    version
    |> cast(attrs, [:context_id, :version, :content, :metadata])
    |> validate_required([:context_id, :version, :content])
    |> foreign_key_constraint(:context_id)
    |> unique_constraint([:context_id, :version], name: "context_versions_context_id_version_index")
  end
end
