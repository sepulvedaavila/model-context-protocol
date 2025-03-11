defmodule McpsWebWeb.Router do
  use McpsWebWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug McpsWebWeb.Plugs.Authentication
  end

  scope "/api", McpsWebWeb do
    pipe_through :api

    # Context Management
    scope "/contexts" do
      get "/", ContextController, :index
      post "/", ContextController, :create
      get "/:id", ContextController, :show
      put "/:id", ContextController, :update
      delete "/:id", ContextController, :delete
      get "/:id/versions", ContextController, :list_versions
      get "/:id/versions/:version", ContextController, :show_version
    end

    # Transformation Pipeline
    scope "/pipelines" do
      get "/", PipelineController, :index
      post "/", PipelineController, :create
      get "/:id", PipelineController, :show
      put "/:id", PipelineController, :update
      delete "/:id", PipelineController, :delete
      post "/:id/apply/:context_id", PipelineController, :apply_pipeline
    end

    # Health check
    get "/health", HealthController, :check
  end

  # Enable Swagger UI
  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :mcps_web,
      swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Model Context Protocol System API",
        description: "API for managing and transforming model contexts"
      },
      basePath: "/api"
    }
  end
end
