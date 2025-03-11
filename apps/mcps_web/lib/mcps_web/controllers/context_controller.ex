defmodule MCPS.Web.ContextController do
  use MCPS.Web, :controller

  alias MCPS.Management.ContextManager
  alias MCPS.Transform.PipelineManager
  alias MCPS.Telemetry.Metrics

  action_fallback MCPS.Web.FallbackController

  def index(conn, params) do
    # Extract query parameters
    owner_id = Map.get(params, "owner_id")
    tags = Map.get(params, "tags", [])
    page = Map.get(params, "page", "1") |> String.to_integer()
    limit = Map.get(params, "limit", "50") |> String.to_integer()

    # Get contexts based on filters
    {:ok, %{data: contexts, pagination: pagination}} =
      ContextManager.list(owner_id: owner_id, tags: tags, page: page, limit: limit)

    render(conn, :index, contexts: contexts, pagination: pagination)
  end

  def create(conn, %{"context" => context_params}) do
    # Extract params
    content = Map.get(context_params, "content", %{})
    metadata = Map.get(context_params, "metadata", %{})
    ttl = Map.get(context_params, "ttl")
    tags = Map.get(context_params, "tags", [])

    # Get user from conn
    user_id = conn.assigns.current_user.id

    # Create context
    with {:ok, context} <- ContextManager.create(content, [
      metadata: metadata,
      ttl: ttl,
      tags: tags,
      owner_id: user_id
    ]) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/contexts/#{context.id}")
      |> render(:show, context: context)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, context} <- ContextManager.get(id) do
      render(conn, :show, context: context)
    end
  end

  def update(conn, %{"id" => id, "context" => context_params}) do
    # Extract params
    content = Map.get(context_params, "content")
    metadata = Map.get(context_params, "metadata")
    tags = Map.get(context_params, "tags")
    change_description = Map.get(context_params, "change_description", "Update via API")

    # Get user from conn
    user_id = conn.assigns.current_user.id

    # Update context
    with {:ok, updated_context} <- ContextManager.update(id, content, [
      metadata: metadata,
      tags: tags,
      change_description: change_description,
      user_id: user_id
    ]) do
      render(conn, :show, context: updated_context)
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- ContextManager.delete(id) do
      send_resp(conn, :no_content, "")
    end
  end

  def versions(conn, %{"id" => id}) do
    with {:ok, versions} <- ContextManager.get_versions(id) do
      render(conn, :versions, versions: versions)
    end
  end

  def apply_pipeline(conn, %{"id" => context_id, "pipeline_id" => pipeline_id}) do
    start_time = System.monotonic_time()

    # Get context and pipeline
    with {:ok, context} <- ContextManager.get(context_id),
         {:ok, pipeline} <- PipelineManager.get(pipeline_id),
         {:ok, transformed_context} <- MCPS.Transform.Pipeline.apply(pipeline, context) do

      # Record telemetry
      end_time = System.monotonic_time()
      Metrics.observe([:mcps, :web, :apply_pipeline], %{
        duration: end_time - start_time
      }, %{
        context_id: context_id,
        pipeline_id: pipeline_id,
        result: :success
      })

      render(conn, :show, context: transformed_context)
    else
      error ->
        # Record telemetry for error
        end_time = System.monotonic_time()
        Metrics.observe([:mcps, :web, :apply_pipeline], %{
          duration: end_time - start_time
        }, %{
          context_id: context_id,
          pipeline_id: pipeline_id,
          result: :error,
          error: inspect(error)
        })

        error
    end
  end
end
