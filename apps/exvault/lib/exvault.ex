defmodule ExVault do
  @moduledoc """
  TODO: Proper documentation for ExVault.
  """

  alias ExVault.Response

  @middleware [
    Tesla.Middleware.JSON
  ]

  @adapter Tesla.Adapter.Hackney

  @type option() ::
          {:address, String.t()}
          | {:token, String.t()}
          | {:adapter, Tesla.Client.adapter()}

  @type client :: Tesla.Client.t()
  @type body :: Tesla.Env.body()
  @type response :: Response.t()

  @doc """
  Create a new `ExVault` client.

  Options:
   * `:address` - The base URL of the Vault server to talk to. (Required)
   * `:token` - The Vault token to authenticate with. If not provided, any
     calls requiring authentication will fail.
   * `:adapter` - The Tesla adapter to use. Defaults to
     `Tesla.Adapter.Hackney`, which has the best out-of-the-box TLS support.
     Don't change this without a specific reason.
  """
  @spec new([option()]) :: client()
  def new(opts) do
    middleware =
      [
        {Tesla.Middleware.BaseUrl, opts[:address]},
        {Tesla.Middleware.Headers, [{"X-Vault-Token", opts[:token]}]}
      ] ++ @middleware

    adapter = opts[:adapter] || @adapter

    Tesla.client(middleware, adapter)
  end

  @doc """
  Perform a 'read' operation.

  Params:
   * `client` must be an `t:ExVault.client/0` value, as constructed by
     `ExVault.new/1`.
   * `path` is the full path of the entity to read.
   * `opts` is currently unused. FIXME
  """
  @spec read(client(), String.t(), keyword()) :: Response.t()
  def read(client, path, opts \\ []) do
    client
    |> Tesla.get("/v1/#{path}", opts)
    |> Response.parse_response()
  end

  @doc """
  Perform a 'write' operation.

  Params:
   * `client` must be an `t:ExVault.client/0` value, as constructed by
     `ExVault.new/1`.
   * `path` is the full path of the entity to write.
   * `params` should be the data to be written, usually in the form of an
     Elixir map.
  """
  @spec write(client(), String.t(), body()) :: Response.t()
  def write(client, path, params) do
    client
    |> Tesla.post("/v1/#{path}", params)
    |> Response.parse_response()
  end

  @doc """
  Perform a 'delete' operation.

  Params:
   * `client` must be an `t:ExVault.client/0` value, as constructed by
     `ExVault.new/1`.
   * `path` is the full path of the entity to delete.
  """
  @spec delete(client(), String.t()) :: Response.t()
  def delete(client, path) do
    client
    |> Tesla.request(url: "/v1/#{path}", method: "DELETE")
    |> Response.parse_response()
  end

  @doc """
  Perform a 'list' operation.

  Params:
   * `client` must be an `t:ExVault.client/0` value, as constructed by
     `ExVault.new/1`.
   * `path` is the full path of the entity to list.
  """
  @spec list(client(), String.t()) :: Response.t()
  def list(client, path) do
    client
    |> Tesla.request(url: "/v1/#{path}", method: "LIST")
    |> Response.parse_response()
  end
end
