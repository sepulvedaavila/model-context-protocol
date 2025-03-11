defmodule MCPS.Web.Swagger do
  @moduledoc """
  Swagger definitions for the API.
  """

  use PhoenixSwagger

  def swagger_definitions do
    %{
      Context: swagger_schema do
        title "Context"
        description "A model context"
        properties do
          id :string, "Unique identifier", required: true
          content :object, "Context content", required: true
          metadata :object, "Context metadata"
          version :integer, "Context version", required: true
          created_at :string, "Creation timestamp", format: "date-time", required: true
          updated_at :string, "Last update timestamp", format: "date-time", required: true
          ttl :integer, "Time-to-live in seconds"
          owner_id :string, "Owner identifier", required: true
          tags array(:string), "Context tags"
        end
      end,

      ContextRequest: swagger_schema do
        title "Context Request"
        description "Request body for creating or updating a context"
        properties do
          content :object, "Context content", required: true
          metadata :object, "Context metadata"
          ttl :integer, "Time-to-live in seconds"
          tags array(:string), "Context tags"
          change_description :string, "Description of changes (for updates)"
        end
      end,

      Pipeline: swagger_schema do
        title "Transformation Pipeline"
        description "A pipeline for transforming contexts"
        properties do
          id :string, "Unique identifier", required: true
          name :string, "Pipeline name", required: true
          description :string, "Pipeline description"
          transformers array(:object), "List of transformers", required: true
          created_at :string, "Creation timestamp", format: "date-time", required: true
          updated_at :string, "Last update timestamp", format: "date-time", required: true
          owner_id :string, "Owner identifier", required: true
          active :boolean, "Whether the pipeline is active", required: true
        end
      end
    }
  end
end
