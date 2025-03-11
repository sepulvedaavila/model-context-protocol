defmodule MCPS.Management.Repo do
  use Ecto.Repo,
    otp_app: :mcps_management,
    adapter: Ecto.Adapters.Postgres

  alias MCPS.Management.Schemas.Context
  alias MCPS.Management.Schemas.ContextVersion
  alias MCPS.Core.Context, as: ContextStruct

  @doc """
  Inserts a context.

  Returns {:ok, context} on success, {:error, changeset} on failure.
  """
  def insert_context(%ContextStruct{} = context) do
    # Convert to schema and insert
    changeset = Context.from_context(context)

    with {:ok, schema} <- insert(changeset) do
      # Create a version record
      version_attrs = %{
        context_id: schema.id,
        version: schema.version,
        content: schema.content,
        metadata: schema.metadata
      }

      {:ok, _version} = insert(ContextVersion.changeset(%ContextVersion{}, version_attrs))

      # Return the domain struct
      {:ok, Context.to_context(schema)}
    end
  end

  @doc """
  Gets a context by ID.

  Returns {:ok, context} if found, {:error, :not_found} otherwise.
  """
  def get_context(id) when is_binary(id) do
    case get(Context, id) do
      nil -> {:error, :not_found}
      schema -> {:ok, Context.to_context(schema)}
    end
  end

  @doc """
  Updates a context.

  Returns {:ok, updated_context} on success, {:error, reason} on failure.
  """
  def update_context(%ContextStruct{} = context) do
    case get(Context, context.id) do
      nil ->
        {:error, :not_found}

      existing ->
        # Increment version
        updated_context = %{context | version: existing.version + 1}
        changeset = Context.from_context(updated_context)

        with {:ok, schema} <- update(changeset) do
          # Create a version record
          version_attrs = %{
            context_id: schema.id,
            version: schema.version,
            content: schema.content,
            metadata: schema.metadata
          }

          {:ok, _version} = insert(ContextVersion.changeset(%ContextVersion{}, version_attrs))

          # Return the domain struct
          {:ok, Context.to_context(schema)}
        end
    end
  end

  @doc """
  Deletes a context.

  Returns {:ok, deleted_context} on success, {:error, reason} on failure.
  """
  def delete_context(id) when is_binary(id) do
    case get(Context, id) do
      nil ->
        {:error, :not_found}

      schema ->
        # Delete the context (versions will be deleted via DB constraints)
        with {:ok, deleted} <- delete(schema) do
          {:ok, Context.to_context(deleted)}
        end
    end
  end

  @doc """
  Lists contexts with optional filtering.

  Options:
  - :owner_id - Filter by owner
  - :tags - Filter by tags (list)
  - :limit - Maximum number of results (default: 100)
  - :offset - Offset for pagination (default: 0)

  Returns a list of context structs.
  """
  def list_contexts(opts \\ []) do
    import Ecto.Query

    owner_id = Keyword.get(opts, :owner_id)
    tags = Keyword.get(opts, :tags, [])
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    query = from c in Context

    query = if owner_id, do: where(query, [c], c.owner_id == ^owner_id), else: query

    query = if tags != [], do: where(query, [c], fragment("? && ?", c.tags, ^tags)), else: query

    query
    |> limit(^limit)
    |> offset(^offset)
    |> order_by([c], desc: c.updated_at)
    |> all()
    |> Enum.map(&Context.to_context/1)
  end

  @doc """
  Gets a specific version of a context.

  Returns {:ok, context} if found, {:error, :not_found} otherwise.
  """
  def get_context_version(id, version) when is_binary(id) and is_integer(version) do
    import Ecto.Query

    query = from v in ContextVersion,
            where: v.context_id == ^id and v.version == ^version

    case one(query) do
      nil ->
        {:error, :not_found}

      version_schema ->
        context = %ContextStruct{
          id: version_schema.context_id,
          content: version_schema.content,
          metadata: version_schema.metadata,
          version: version_schema.version,
          created_at: version_schema.inserted_at,
          updated_at: version_schema.updated_at
        }

        {:ok, context}
    end
  end

  # Add other repository functions...
end
