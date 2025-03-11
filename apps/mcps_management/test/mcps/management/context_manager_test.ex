defmodule MCPS.Management.ContextManagerTest do
  use MCPS.Management.DataCase, async: true

  alias MCPS.Management.ContextManager
  alias MCPS.Core.Context

  describe "create/2" do
    test "creates a context with valid data" do
      content = %{"text" => "Sample context content"}

      {:ok, context} = ContextManager.create(content, owner_id: "user_123")

      assert context.content["text"] == "Sample context content"
      assert context.owner_id == "user_123"
      assert context.version == 1
      assert not is_nil(context.id)
    end

    test "returns error with invalid data" do
      # Test various invalid data scenarios
      # ...
    end
  end

  describe "get/1" do
    test "retrieves a context by ID" do
      # Create a context first
      {:ok, created} = ContextManager.create(%{"data" => "test"}, owner_id: "user_123")

      # Retrieve it
      {:ok, retrieved} = ContextManager.get(created.id)

      assert retrieved.id == created.id
      assert retrieved.content["data"] == "test"
    end

    test "returns error for non-existent ID" do
      assert {:error, :not_found} = ContextManager.get("non_existent_id")
    end
  end

  # Add more tests for other functions...
end
