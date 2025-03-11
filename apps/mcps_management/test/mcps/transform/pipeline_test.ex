defmodule MCPS.Transform.PipelineTest do
  use ExUnit.Case, async: true

  alias MCPS.Transform.Pipeline
  alias MCPS.Core.Context

  describe "apply/2" do
    test "applies a pipeline to a context" do
      # Create a test context
      context = %Context{
        id: "test_id",
        content: %{"text" => "Sample TEXT"},
        metadata: %{},
        version: 1,
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        owner_id: "user_123",
        tags: []
      }

      # Create a test pipeline with a text normalizer
      pipeline = %Pipeline{
        id: "pipeline_123",
        name: "Test Pipeline",
        transformers: [
          {MCPS.Transform.Transformers.TextNormalizer, [lowercase: true]}
        ],
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        owner_id: "user_123",
        active: true
      }

      # Apply the pipeline
      {:ok, transformed} = Pipeline.apply(pipeline, context)

      # Verify transformation
      assert transformed.content["text"] == "sample text"
      assert transformed.metadata["normalized"] == true
    end

    test "returns error when a transformer fails" do
      # Test pipeline with a transformer that fails
      # ...
    end
  end

  # Add more tests...
end
