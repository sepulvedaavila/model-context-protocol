defmodule McpsWebWeb.PipelineController do
  use McpsWebWeb, :controller
  use PhoenixSwagger

  alias MCPS.Transform.Pipeline
  alias MCPS.Management.Repo
  alias MCPS.Telemetry.Metrics

  # Swagger documentation
  swagger_path :index do
    get("/api/pipelines")
    summary("List pipelines")
    description("List all transformation pipelines with optional filtering")
    parameter(:query, :owner_id, :string, "Filter by owner ID", required: false)
    parameter(:query, :active, :boolean, "Filter by active status", required: false)
    parameter(:query, :limit, :integer, "Maximum number of results", required: false)
    parameter(:query, :offset, :integer, "Offset for pagination", required: false)
    response(200, "Success", Schema.array(:Pipeline))
    response(401, "Unauthorized")
  end

  def index(conn, _params) do
    # This would be implemented to list all pipelines
    # For now, we'll return a placeholder
    conn
    |> put_status(:not_implemented)
    |> json(%{error: "Not implemented yet"})
  end

  swagger_path :create do
    post("/api/pipelines")
    summary("Create pipeline")
    description("Create a new transformation pipeline")

    parameter(:body, :pipeline, :object, "Pipeline object",
      required: true,
      schema: %{
        type: :object,
        required: [:name, :transformers],
        properties: %{
          id: %{
            type: :string,
            description: "Pipeline ID (optional, will be generated if not provided)"
          },
          name: %{type: :string, description: "Pipeline name"},
          description: %{type: :string, description: "Pipeline description"},
          transformers: %{
            type: :array,
            description: "List of transformers",
            items: %{
              type: :object,
              required: [:module, :options],
              properties: %{
                module: %{type: :string, description: "Transformer module name"},
                options: %{type: :object, description: "Transformer options"}
              }
            }
          },
          active: %{type: :boolean, description: "Whether the pipeline is active"}
        }
      }
    )

    response(201, "Created", Schema.ref(:Pipeline))
    response(400, "Bad Request")
    response(401, "Unauthorized")
  end

  def create(conn, params) do
    start_time = System.monotonic_time()

    # Generate ID if not provided
    id = params["id"] || generate_id()

    # Parse transformers
    transformers = parse_transformers(params["transformers"] || [])

    # Create pipeline struct
    pipeline = %Pipeline{
      id: id,
      name: params["name"],
      description: params["description"],
      transformers: transformers,
      owner_id: conn.assigns[:user_id],
      active: Map.get(params, "active", true),
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    # Validate pipeline
    case Pipeline.validate(pipeline) do
      :ok ->
        # In a real implementation, we would save the pipeline to a repository
        # For now, we'll just return the created pipeline

        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :pipeline, :create],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            pipeline_id: pipeline.id,
            result: :success
          }
        )

        conn
        |> put_status(:created)
        |> render(:show, pipeline: pipeline)

      {:error, reason} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :pipeline, :create],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            result: :error,
            reason: "validation_error"
          }
        )

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid pipeline", details: reason})
    end
  end

  swagger_path :show do
    get("/api/pipelines/{id}")
    summary("Get pipeline")
    description("Get a pipeline by ID")
    parameter(:path, :id, :string, "Pipeline ID", required: true)
    response(200, "Success", Schema.ref(:Pipeline))
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def show(conn, %{"id" => _id}) do
    # This would be implemented to get a pipeline by ID
    # For now, we'll return a placeholder
    conn
    |> put_status(:not_implemented)
    |> json(%{error: "Not implemented yet"})
  end

  swagger_path :update do
    put("/api/pipelines/{id}")
    summary("Update pipeline")
    description("Update an existing pipeline")
    parameter(:path, :id, :string, "Pipeline ID", required: true)

    parameter(:body, :pipeline, :object, "Pipeline object",
      required: true,
      schema: %{
        type: :object,
        properties: %{
          name: %{type: :string, description: "Pipeline name"},
          description: %{type: :string, description: "Pipeline description"},
          transformers: %{
            type: :array,
            description: "List of transformers",
            items: %{
              type: :object,
              required: [:module, :options],
              properties: %{
                module: %{type: :string, description: "Transformer module name"},
                options: %{type: :object, description: "Transformer options"}
              }
            }
          },
          active: %{type: :boolean, description: "Whether the pipeline is active"}
        }
      }
    )

    response(200, "Success", Schema.ref(:Pipeline))
    response(400, "Bad Request")
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def update(conn, %{"id" => _id}) do
    # This would be implemented to update a pipeline
    # For now, we'll return a placeholder
    conn
    |> put_status(:not_implemented)
    |> json(%{error: "Not implemented yet"})
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/pipelines/{id}")
    summary("Delete pipeline")
    description("Delete a pipeline by ID")
    parameter(:path, :id, :string, "Pipeline ID", required: true)
    response(200, "Success")
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def delete(conn, %{"id" => _id}) do
    # This would be implemented to delete a pipeline
    # For now, we'll return a placeholder
    conn
    |> put_status(:not_implemented)
    |> json(%{error: "Not implemented yet"})
  end

  swagger_path :apply_pipeline do
    post("/api/pipelines/{id}/apply/{context_id}")
    summary("Apply pipeline")
    description("Apply a pipeline to a context")
    parameter(:path, :id, :string, "Pipeline ID", required: true)
    parameter(:path, :context_id, :string, "Context ID", required: true)
    response(200, "Success", Schema.ref(:Context))
    response(400, "Bad Request")
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def apply_pipeline(conn, %{"id" => pipeline_id, "context_id" => context_id}) do
    start_time = System.monotonic_time()

    # Get context
    with {:ok, context} <- Repo.get_context(context_id),
         # Get pipeline (in a real implementation)
         {:ok, pipeline} <- get_pipeline(pipeline_id),
         # Apply pipeline
         {:ok, transformed} <- Pipeline.apply(pipeline, context) do
      # Record telemetry
      end_time = System.monotonic_time()

      Metrics.observe(
        [:mcps, :web, :pipeline, :apply],
        %{
          duration: end_time - start_time
        },
        %{
          user_id: conn.assigns[:user_id],
          pipeline_id: pipeline_id,
          context_id: context_id,
          result: :success
        }
      )

      # Return transformed context
      conn
      |> render(McpsWebWeb.ContextJSON, :show, context: transformed)
    else
      {:error, :not_found} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :pipeline, :apply],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            pipeline_id: pipeline_id,
            context_id: context_id,
            result: :error,
            reason: "not_found"
          }
        )

        conn
        |> put_status(:not_found)
        |> json(%{error: "Pipeline or context not found"})

      {:error, reason} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :pipeline, :apply],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            pipeline_id: pipeline_id,
            context_id: context_id,
            result: :error,
            reason: inspect(reason)
          }
        )

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Failed to apply pipeline", details: reason})
    end
  end

  # Helper functions

  # Generate a random ID
  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  # Parse transformers from params
  defp parse_transformers(transformers) do
    Enum.map(transformers, fn transformer ->
      module_name = transformer["module"]
      options = transformer["options"] || %{}

      # Convert module name to actual module
      module = String.to_existing_atom("Elixir.#{module_name}")

      # Convert options map to keyword list
      options = Enum.map(options, fn {k, v} -> {String.to_atom(k), v} end)

      {module, options}
    end)
  end

  # Get pipeline by ID (placeholder)
  defp get_pipeline(id) do
    # In a real implementation, this would fetch from a repository
    # For now, we'll create a dummy pipeline
    pipeline = %Pipeline{
      id: id,
      name: "Dummy Pipeline",
      description: "A dummy pipeline for testing",
      transformers: [
        {MCPS.Transform.Transformers.TextNormalizer,
         [fields: ["text"], lowercase: true, trim: true]}
      ],
      owner_id: "system",
      active: true,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    {:ok, pipeline}
  end
end
