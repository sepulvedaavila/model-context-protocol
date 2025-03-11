defmodule McpsWebWeb.ContextController do
  use McpsWebWeb, :controller
  use PhoenixSwagger

  alias MCPS.Management.Repo
  alias MCPS.Core.Context
  alias MCPS.Telemetry.Metrics

  # Swagger documentation
  swagger_path :index do
    get("/api/contexts")
    summary("List contexts")
    description("List all contexts with optional filtering")
    parameter(:query, :owner_id, :string, "Filter by owner ID", required: false)
    parameter(:query, :tags, :array, "Filter by tags", items: [type: :string], required: false)
    parameter(:query, :limit, :integer, "Maximum number of results", required: false)
    parameter(:query, :offset, :integer, "Offset for pagination", required: false)
    response(200, "Success", Schema.array(:Context))
    response(401, "Unauthorized")
  end

  def index(conn, params) do
    start_time = System.monotonic_time()

    # Extract filter parameters
    filters = [
      owner_id: params["owner_id"],
      tags: params["tags"] || [],
      limit: parse_int_param(params["limit"], 100),
      offset: parse_int_param(params["offset"], 0)
    ]

    # Get contexts
    contexts = Repo.list_contexts(filters)

    # Record telemetry
    end_time = System.monotonic_time()

    Metrics.observe(
      [:mcps, :web, :context, :list],
      %{
        duration: end_time - start_time
      },
      %{
        user_id: conn.assigns[:user_id],
        filter_count: length(Enum.filter(filters, fn {_, v} -> v != nil end)),
        result_count: length(contexts)
      }
    )

    render(conn, :index, contexts: contexts)
  end

  swagger_path :create do
    post("/api/contexts")
    summary("Create context")
    description("Create a new context")

    parameter(:body, :context, :object, "Context object",
      required: true,
      schema: %{
        type: :object,
        required: [:id, :content],
        properties: %{
          id: %{type: :string, description: "Context ID"},
          content: %{type: :object, description: "Context content"},
          metadata: %{type: :object, description: "Context metadata"},
          ttl: %{type: :integer, description: "Time to live in seconds"},
          tags: %{type: :array, items: %{type: :string}, description: "Tags"}
        }
      }
    )

    response(201, "Created", Schema.ref(:Context))
    response(400, "Bad Request")
    response(401, "Unauthorized")
  end

  def create(conn, params) do
    start_time = System.monotonic_time()

    # Create context struct
    context = %Context{
      id: params["id"],
      content: params["content"],
      metadata: params["metadata"] || %{},
      version: 1,
      ttl: params["ttl"],
      owner_id: conn.assigns[:user_id],
      tags: params["tags"] || [],
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    # Validate and insert
    case Context.validate(context) do
      :ok ->
        case Repo.insert_context(context) do
          {:ok, created} ->
            # Record telemetry
            end_time = System.monotonic_time()

            Metrics.observe(
              [:mcps, :web, :context, :create],
              %{
                duration: end_time - start_time
              },
              %{
                user_id: conn.assigns[:user_id],
                context_id: created.id,
                result: :success
              }
            )

            conn
            |> put_status(:created)
            |> render(:show, context: created)

          {:error, changeset} ->
            # Record telemetry
            end_time = System.monotonic_time()

            Metrics.observe(
              [:mcps, :web, :context, :create],
              %{
                duration: end_time - start_time
              },
              %{
                user_id: conn.assigns[:user_id],
                result: :error,
                reason: "database_error"
              }
            )

            conn
            |> put_status(:bad_request)
            |> json(%{error: "Invalid context", details: format_errors(changeset)})
        end

      {:error, reason} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :context, :create],
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
        |> json(%{error: "Invalid context", details: reason})
    end
  end

  swagger_path :show do
    get("/api/contexts/{id}")
    summary("Get context")
    description("Get a context by ID")
    parameter(:path, :id, :string, "Context ID", required: true)
    response(200, "Success", Schema.ref(:Context))
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def show(conn, %{"id" => id}) do
    start_time = System.monotonic_time()

    case Repo.get_context(id) do
      {:ok, context} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :context, :get],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            context_id: id,
            result: :success
          }
        )

        render(conn, :show, context: context)

      {:error, :not_found} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :context, :get],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            context_id: id,
            result: :error,
            reason: "not_found"
          }
        )

        conn
        |> put_status(:not_found)
        |> json(%{error: "Context not found"})
    end
  end

  swagger_path :update do
    put("/api/contexts/{id}")
    summary("Update context")
    description("Update an existing context")
    parameter(:path, :id, :string, "Context ID", required: true)

    parameter(:body, :context, :object, "Context object",
      required: true,
      schema: %{
        type: :object,
        properties: %{
          content: %{type: :object, description: "Context content"},
          metadata: %{type: :object, description: "Context metadata"},
          ttl: %{type: :integer, description: "Time to live in seconds"},
          tags: %{type: :array, items: %{type: :string}, description: "Tags"}
        }
      }
    )

    response(200, "Success", Schema.ref(:Context))
    response(400, "Bad Request")
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def update(conn, %{"id" => id} = params) do
    start_time = System.monotonic_time()

    # Get existing context
    case Repo.get_context(id) do
      {:ok, existing} ->
        # Check ownership
        if existing.owner_id != conn.assigns[:user_id] do
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You don't have permission to update this context"})
        else
          # Update context
          updated = %{
            existing
            | content: params["content"] || existing.content,
              metadata: params["metadata"] || existing.metadata,
              ttl: params["ttl"] || existing.ttl,
              tags: params["tags"] || existing.tags,
              updated_at: DateTime.utc_now()
          }

          case Repo.update_context(updated) do
            {:ok, context} ->
              # Record telemetry
              end_time = System.monotonic_time()

              Metrics.observe(
                [:mcps, :web, :context, :update],
                %{
                  duration: end_time - start_time
                },
                %{
                  user_id: conn.assigns[:user_id],
                  context_id: id,
                  result: :success
                }
              )

              render(conn, :show, context: context)

            {:error, changeset} ->
              # Record telemetry
              end_time = System.monotonic_time()

              Metrics.observe(
                [:mcps, :web, :context, :update],
                %{
                  duration: end_time - start_time
                },
                %{
                  user_id: conn.assigns[:user_id],
                  context_id: id,
                  result: :error,
                  reason: "database_error"
                }
              )

              conn
              |> put_status(:bad_request)
              |> json(%{error: "Invalid context", details: format_errors(changeset)})
          end
        end

      {:error, :not_found} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :context, :update],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            context_id: id,
            result: :error,
            reason: "not_found"
          }
        )

        conn
        |> put_status(:not_found)
        |> json(%{error: "Context not found"})
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/contexts/{id}")
    summary("Delete context")
    description("Delete a context by ID")
    parameter(:path, :id, :string, "Context ID", required: true)
    response(200, "Success")
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def delete(conn, %{"id" => id}) do
    start_time = System.monotonic_time()

    # Get existing context to check ownership
    case Repo.get_context(id) do
      {:ok, existing} ->
        # Check ownership
        if existing.owner_id != conn.assigns[:user_id] do
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You don't have permission to delete this context"})
        else
          # Delete context
          case Repo.delete_context(id) do
            {:ok, _} ->
              # Record telemetry
              end_time = System.monotonic_time()

              Metrics.observe(
                [:mcps, :web, :context, :delete],
                %{
                  duration: end_time - start_time
                },
                %{
                  user_id: conn.assigns[:user_id],
                  context_id: id,
                  result: :success
                }
              )

              conn
              |> put_status(:ok)
              |> json(%{message: "Context deleted successfully"})

            {:error, reason} ->
              # Record telemetry
              end_time = System.monotonic_time()

              Metrics.observe(
                [:mcps, :web, :context, :delete],
                %{
                  duration: end_time - start_time
                },
                %{
                  user_id: conn.assigns[:user_id],
                  context_id: id,
                  result: :error,
                  reason: "database_error"
                }
              )

              conn
              |> put_status(:internal_server_error)
              |> json(%{error: "Failed to delete context", details: reason})
          end
        end

      {:error, :not_found} ->
        # Record telemetry
        end_time = System.monotonic_time()

        Metrics.observe(
          [:mcps, :web, :context, :delete],
          %{
            duration: end_time - start_time
          },
          %{
            user_id: conn.assigns[:user_id],
            context_id: id,
            result: :error,
            reason: "not_found"
          }
        )

        conn
        |> put_status(:not_found)
        |> json(%{error: "Context not found"})
    end
  end

  swagger_path :list_versions do
    get("/api/contexts/{id}/versions")
    summary("List context versions")
    description("List all versions of a context")
    parameter(:path, :id, :string, "Context ID", required: true)
    response(200, "Success", Schema.array(:ContextVersion))
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def list_versions(conn, %{"id" => id}) do
    # This would be implemented to list all versions of a context
    # For now, we'll return a placeholder
    conn
    |> put_status(:not_implemented)
    |> json(%{error: "Not implemented yet"})
  end

  swagger_path :show_version do
    get("/api/contexts/{id}/versions/{version}")
    summary("Get context version")
    description("Get a specific version of a context")
    parameter(:path, :id, :string, "Context ID", required: true)
    parameter(:path, :version, :integer, "Version number", required: true)
    response(200, "Success", Schema.ref(:Context))
    response(401, "Unauthorized")
    response(404, "Not Found")
  end

  def show_version(conn, %{"id" => id, "version" => version_str}) do
    start_time = System.monotonic_time()

    # Parse version
    version = parse_int_param(version_str, nil)

    if is_nil(version) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid version number"})
    else
      case Repo.get_context_version(id, version) do
        {:ok, context} ->
          # Record telemetry
          end_time = System.monotonic_time()

          Metrics.observe(
            [:mcps, :web, :context, :get_version],
            %{
              duration: end_time - start_time
            },
            %{
              user_id: conn.assigns[:user_id],
              context_id: id,
              version: version,
              result: :success
            }
          )

          render(conn, :show, context: context)

        {:error, :not_found} ->
          # Record telemetry
          end_time = System.monotonic_time()

          Metrics.observe(
            [:mcps, :web, :context, :get_version],
            %{
              duration: end_time - start_time
            },
            %{
              user_id: conn.assigns[:user_id],
              context_id: id,
              version: version,
              result: :error,
              reason: "not_found"
            }
          )

          conn
          |> put_status(:not_found)
          |> json(%{error: "Context version not found"})
      end
    end
  end

  # Helper functions

  defp parse_int_param(nil, default), do: default

  defp parse_int_param(param, default) when is_binary(param) do
    case Integer.parse(param) do
      {value, ""} -> value
      _ -> default
    end
  end

  defp parse_int_param(param, _default) when is_integer(param), do: param
  defp parse_int_param(_, default), do: default

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
