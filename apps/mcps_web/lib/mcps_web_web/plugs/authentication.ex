defmodule McpsWebWeb.Plugs.Authentication do
  @moduledoc """
  Plug for API authentication.
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    with {auth_type, token} <- get_auth_header(conn),
         {:ok, user_id} <- authenticate(auth_type, token) do
      # Add user_id to conn assigns
      conn
      |> assign(:authenticated, true)
      |> assign(:user_id, user_id)
    else
      :missing_auth_header ->
        # Allow unauthenticated access to health check
        if health_check_path?(conn) do
          conn
        else
          unauthorized(conn)
        end

      {:error, reason} ->
        Logger.warning("Authentication failed: #{reason}")
        unauthorized(conn)
    end
  end

  # Get authentication header
  defp get_auth_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:bearer, token}
      ["ApiKey " <> token] -> {:api_key, token}
      [] -> :missing_auth_header
      _ -> {:error, "invalid_auth_header"}
    end
  end

  # Authenticate based on auth type
  defp authenticate(:bearer, token) do
    # In production, this would validate a JWT or OAuth token
    # For now, we'll just extract a user ID from the token
    case validate_token(token) do
      {:ok, claims} -> {:ok, claims["sub"]}
      error -> error
    end
  end

  defp authenticate(:api_key, token) do
    # In production, this would validate against stored API keys
    # For now, we'll just check if it's a valid format
    if String.length(token) >= 32 do
      # Extract user ID from API key (in production, would look up in database)
      {:ok,
       "api_user_#{:crypto.hash(:md5, token) |> Base.encode16(case: :lower) |> binary_part(0, 8)}"}
    else
      {:error, "invalid_api_key"}
    end
  end

  # Validate JWT token (simplified for development)
  defp validate_token(token) do
    # In production, this would properly validate the JWT
    # For now, we'll just check if it looks like a JWT and extract a fake user ID
    case String.split(token, ".") do
      [_header, _payload, _signature] ->
        # Return a fake user ID based on token hash
        {:ok,
         %{
           "sub" =>
             "user_#{:crypto.hash(:md5, token) |> Base.encode16(case: :lower) |> binary_part(0, 8)}"
         }}

      _ ->
        {:error, "invalid_token_format"}
    end
  end

  # Return 401 Unauthorized
  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "unauthorized"}))
    |> halt()
  end

  # Check if the request is for the health check endpoint
  defp health_check_path?(conn) do
    conn.request_path == "/api/health"
  end
end
