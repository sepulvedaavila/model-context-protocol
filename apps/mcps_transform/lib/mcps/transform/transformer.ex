defmodule MCPS.Transform.Transformer do
  @moduledoc """
  Behaviour for context transformers.
  """

  alias MCPS.Core.Context

  @doc """
  Transforms a context.

  Returns {:ok, transformed_context} on success.
  Returns {:error, reason} on failure.
  """
  @callback transform(Context.t(), keyword()) :: {:ok, Context.t()} | {:error, term()}

  @doc """
  Validates transformer options.

  Returns :ok if valid, {:error, reason} otherwise.
  """
  @callback validate_options(keyword()) :: :ok | {:error, term()}
end
