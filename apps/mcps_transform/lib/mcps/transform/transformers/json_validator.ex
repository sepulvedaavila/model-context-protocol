defmodule MCPS.Transform.Transformers.JsonValidator do
  @moduledoc """
  A transformer that validates JSON fields in a context against a schema.
  """

  @behaviour MCPS.Transform.Transformer

  alias MCPS.Core.Context

  @doc """
  Validates JSON fields in a context against a schema.

  Options:
  - :fields - List of field paths to validate (default: ["content"])
  - :schema - JSON Schema to validate against (required)
  - :fail_on_error - Whether to fail if validation fails (default: true)
  """
  @impl true
  def transform(%Context{} = context, opts \\ []) do
    fields = Keyword.get(opts, :fields, ["content"])
    schema = Keyword.get(opts, :schema)
    fail_on_error = Keyword.get(opts, :fail_on_error, true)

    if is_nil(schema) do
      {:error, "Schema is required for JSON validation"}
    else
      # Parse schema if it's a string
      schema = if is_binary(schema), do: Jason.decode!(schema), else: schema

      # Validate each field
      {valid, errors} = validate_fields(context.content, fields, schema)

      if valid or not fail_on_error do
        # Update metadata with validation results
        metadata = Map.put(context.metadata, "json_validation", %{
          valid: valid,
          errors: errors,
          validated_at: DateTime.utc_now() |> DateTime.to_iso8601()
        })

        # Return updated context
        {:ok, %{context | metadata: metadata}}
      else
        # Return error if validation failed and fail_on_error is true
        {:error, "JSON validation failed: #{inspect(errors)}"}
      end
    end
  end

  @impl true
  def validate_options(opts) do
    schema = [
      fields: [type: {:list, :string}, required: false],
      schema: [required: true],
      fail_on_error: [type: :boolean, required: false]
    ]

    NimbleOptions.validate(opts, schema)
  end

  # Private functions

  defp validate_fields(content, fields, schema) do
    Enum.reduce(fields, {true, []}, fn field, {valid_acc, errors_acc} ->
      # Get the value at the field path
      field_path = String.split(field, ".")
      value = get_in_path(content, field_path)

      # Validate value against schema
      case validate_json(value, schema) do
        :ok ->
          {valid_acc, errors_acc}

        {:error, errors} ->
          {false, [{field, errors} | errors_acc]}
      end
    end)
  end

  defp get_in_path(data, [key | rest]) when is_map(data) do
    case Map.fetch(data, key) do
      {:ok, value} ->
        if rest == [], do: value, else: get_in_path(value, rest)
      :error ->
        case Map.fetch(data, String.to_atom(key)) do
          {:ok, value} ->
            if rest == [], do: value, else: get_in_path(value, rest)
          :error ->
            nil
        end
    end
  end
  defp get_in_path(_data, _path), do: nil

  defp validate_json(value, schema) do
    # In a real implementation, this would use a proper JSON Schema validator
    # For now, we'll just do a simple type check
    case schema["type"] do
      "object" when not is_map(value) ->
        {:error, "Expected object, got #{inspect(value)}"}

      "array" when not is_list(value) ->
        {:error, "Expected array, got #{inspect(value)}"}

      "string" when not is_binary(value) ->
        {:error, "Expected string, got #{inspect(value)}"}

      "number" when not is_number(value) ->
        {:error, "Expected number, got #{inspect(value)}"}

      "integer" when not is_integer(value) ->
        {:error, "Expected integer, got #{inspect(value)}"}

      "boolean" when not is_boolean(value) ->
        {:error, "Expected boolean, got #{inspect(value)}"}

      "null" when not is_nil(value) ->
        {:error, "Expected null, got #{inspect(value)}"}

      _ ->
        :ok
    end
  end
end
