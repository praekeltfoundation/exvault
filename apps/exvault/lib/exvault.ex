defmodule ExVault do
  @moduledoc """
  TODO: Documentation for ExVault.
  """

  alias ExVault.Response

  @middleware [
    Tesla.Middleware.JSON
  ]

  @adapter Tesla.Adapter.Hackney

  @type client :: Tesla.Client.t()
  @type body :: Tesla.Env.body()
  @type response :: Response.t()

  @spec new(keyword()) :: client()
  def new(opts) do
    middleware =
      [
        {Tesla.Middleware.BaseUrl, opts[:baseurl]},
        {Tesla.Middleware.Headers, [{"X-Vault-Token", opts[:token]}]}
      ] ++ @middleware

    adapter = opts[:adapter] || @adapter

    Tesla.client(middleware, adapter)
  end

  @spec read(client(), String.t(), String.t(), keyword()) :: Response.t()
  def read(client, mount, path, opts \\ []) do
    client
    |> Tesla.get("/v1/#{mount}/#{path}", opts)
    |> Response.parse_response()
  end

  @spec write(client(), String.t(), String.t(), body()) :: Response.t()
  def write(client, mount, path, params) do
    client
    |> Tesla.post("/v1/#{mount}/#{path}", params)
    |> Response.parse_response()
  end

  @spec delete(client(), String.t(), String.t()) :: Response.t()
  def delete(client, mount, path) do
    client
    |> Tesla.request(url: "/v1/#{mount}/#{path}", method: "DELETE")
    |> Response.parse_response()
  end

  @spec list(client(), String.t(), String.t()) :: Response.t()
  def list(client, mount, path) do
    client
    |> Tesla.request(url: "/v1/#{mount}/#{path}", method: "LIST")
    |> Response.parse_response()
  end
end
