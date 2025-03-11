defmodule McpsWeb.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  # use McpsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug MCPS.Web.Plugs.RequestId
    plug MCPS.Web.Plugs.RequestLogger
  end

  pipeline :auth do
    plug MCPS.Web.Plugs.Authentication
    plug MCPS.Web.Plugs.Authorization
  end

  scope "/api/v1", McpsWeb do
    pipe_through [:api, :auth]

    # Context endpoints
    resources "/contexts", ContextController, except: [:new, :edit]
    get "/contexts/:id/versions", ContextController, :versions
    post "/contexts/:id/apply_pipeline/:pipeline_id", ContextController, :apply_pipeline

    # Pipeline endpoints
    resources "/pipelines", PipelineController, except: [:new, :edit]

    # Transformer endpoints
    get "/transformers", TransformerController, :index
    get "/transformers/:id", TransformerController, :show
  end

  scope "/api/v1", McpsWebWeb do
    pipe_through :api

    # Public endpoints
    get "/health", HealthController, :index
    get "/metrics", MetricsController, :index
  end

  scope "/api/v1", MCPS.Web do
    pipe_through :api

    # Public endpoints
    get "/health", HealthController, :index
    get "/metrics", MetricsController, :index
  end

  # Swagger documentation
  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :mcps_web,
      swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Model Context Protocol Service API"
      }
    }
  end
end
