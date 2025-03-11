defmodule MCPS.Management.Repo.Migrations.CreateContextsTables do
  use Ecto.Migration

  def change do
    # Create contexts table
    create table(:contexts, primary_key: false) do
      add :id, :string, primary_key: true
      add :content, :map, null: false
      add :metadata, :map, default: %{}
      add :version, :integer, null: false, default: 1
      add :ttl, :integer
      add :owner_id, :string, null: false
      add :tags, {:array, :string}, default: []

      timestamps()
    end

    create index(:contexts, [:owner_id])
    create index(:contexts, [:tags], using: "gin")

    # Create context_versions table
    create table(:context_versions) do
      add :context_id, references(:contexts, type: :string, on_delete: :delete_all), null: false
      add :version, :integer, null: false
      add :content, :map, null: false
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:context_versions, [:context_id])
    create unique_index(:context_versions, [:context_id, :version], name: "context_versions_context_id_version_index")
  end
end
