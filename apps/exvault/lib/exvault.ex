defmodule ExVault do
  @moduledoc """
  Documentation for ExVault.
  """

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
    Tesla.get(client, "/v1/#{mount}/#{path}", opts)
  end

  def write(client, mount, path, params) do
    Tesla.post(client, "/v1/#{mount}/#{path}", params)
  end

  def delete(client, mount, path) do
    Tesla.request(client, url: "/v1/#{mount}/#{path}", method: "DELETE")
  end

  def list(client, mount, path) do
    Tesla.request(client, url: "/v1/#{mount}/#{path}", method: "LIST")
  end
end
