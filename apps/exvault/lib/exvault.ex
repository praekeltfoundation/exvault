defmodule ExVault do
  @moduledoc """
  TODO: Documentation for ExVault.
  """

  alias ExVault.Response

  @middleware [
    Tesla.Middleware.JSON
  ]

  @adapter Tesla.Adapter.Hackney

  def new(opts) do
    middleware =
      [
        {Tesla.Middleware.BaseUrl, opts[:baseurl]},
        {Tesla.Middleware.Headers, [{"X-Vault-Token", opts[:token]}]}
      ] ++ @middleware

    adapter = opts[:adapter] || @adapter

    Tesla.client(middleware, adapter)
  end

  def read(client, mount, path, opts \\ []) do
    client
    |> Tesla.get("/v1/#{mount}/#{path}", opts)
    |> Response.parse_response()
  end

  def write(client, mount, path, params) do
    client
    |> Tesla.post("/v1/#{mount}/#{path}", params)
    |> Response.parse_response()
  end

  def delete(client, mount, path) do
    client
    |> Tesla.request(url: "/v1/#{mount}/#{path}", method: "DELETE")
    |> Response.parse_response()
  end

  def list(client, mount, path) do
    client
    |> Tesla.request(url: "/v1/#{mount}/#{path}", method: "LIST")
    |> Response.parse_response()
  end
end
