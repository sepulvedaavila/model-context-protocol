defmodule MCPS.Transform.Transformers.TextNormalizer do
  @moduledoc """
  A transformer that normalizes text fields in a context.
  """

  @behaviour MCPS.Transform.Transformer

  alias MCPS.Core.Context

  @doc """
  Transforms text fields in a context according to options.

  Options:
  - :fields - List of field paths to normalize (default: ["text"])
  - :lowercase - Whether to convert text to lowercase (default: true)
  - :trim - Whether to trim whitespace (default: true)
  - :remove_extra_spaces - Whether to replace multiple spaces with a single space (default: true)
  """
  @impl true
  def transform(%Context{} = context, opts \\ []) do
    fields = Keyword.get(opts, :fields, ["text"])
    lowercase = Keyword.get(opts, :lowercase, true)
    trim = Keyword.get(opts, :trim, true)
    remove_extra_spaces = Keyword.get(opts, :remove_extra_spaces, true)

    # Transform content by normalizing text fields
    transformed_content = normalize_fields(context.content, fields, %{
      lowercase: lowercase,
      trim: trim,
      remove_extra_spaces: remove_extra_spaces
    })

    # Return updated context
    updated_context = %{context |
      content: transformed_content,
      metadata: Map.put(context.metadata, "normalized", true)
    }

    {:ok, updated_context}
  end

  @impl true
  def validate_options(opts) do
    schema = [
      fields: [type: {:list, :string}, required: false],
      lowercase: [type: :boolean, required: false],
      trim: [type: :boolean, required: false],
      remove_extra_spaces: [type: :boolean, required: false]
    ]

    NimbleOptions.validate(opts, schema)
  end

  # Private functions

  defp normalize_fields(content, [], _options), do: content

  defp normalize_fields(content, [field | rest], options) do
    # Get the value at the field path
    field_path = String.split(field, ".")
    updated_content = update_in_path(content, field_path, fn value ->
      normalize_text(value, options)
    end)

    # Process remaining fields
    normalize_fields(updated_content, rest, options)
  end

  defp update_in_path(data, [key], updater) when is_map(data) do
    case Map.fetch(data, key) do
      {:ok, value} -> Map.put(data, key, updater.(value))
      :error -> data
    end
  end

  defp update_in_path(data, [key | rest], updater) when is_map(data) do
    case Map.fetch(data, key) do
      {:ok, value} -> Map.put(data, key, update_in_path(value, rest, updater))
      :error -> data
    end
  end

  defp update_in_path(data, _path, _updater), do: data

  defp normalize_text(text, options) when is_binary(text) do
    text
    |> then(fn t -> if options.lowercase, do: String.downcase(t), else: t end)
    |> then(fn t -> if options.trim, do: String.trim(t), else: t end)
    |> then(fn t ->
      if options.remove_extra_spaces do
        Regex.replace(~r/\s+/, t, " ")
      else
        t
      end
    end)
  end

  defp normalize_text(value, _options), do: value
end
