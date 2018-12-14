defmodule ExVault do
  @moduledoc """
  Documentation for ExVault.
  """

  @middleware [
    Tesla.Middleware.JSON
  ]

  @adapter Tesla.Adapter.Hackney

  defmodule SuccessResponse do
    defstruct [
      :httpstatus,
      :request_id,
      :lease_id,
      :renewable,
      :lease_duration,
      :data,
      :wrap_info,
      :warnings,
      :auth
    ]

    @type t :: %__MODULE__{
            httpstatus: integer,
            request_id: String.t(),
            lease_id: String.t(),
            renewable: boolean,
            lease_duration: integer,
            data: %{},
            # TODO: WrapInfo struct.
            wrap_info: nil,
            warnings: [String.t()],
            # TODO: Auth struct.
            auth: nil
          }

    def from_resp(%{status: 204, body: ""}) do
      %__MODULE__{httpstatus: 204}
    end

    def from_resp(%{status: 200, body: body}) do
      %{
        "request_id" => request_id,
        "lease_id" => lease_id,
        "renewable" => renewable,
        "lease_duration" => lease_duration,
        "data" => data,
        "wrap_info" => wrap_info,
        "warnings" => warnings,
        "auth" => auth
      } = body

      %__MODULE__{
        httpstatus: 200,
        request_id: request_id,
        lease_id: lease_id,
        renewable: renewable,
        lease_duration: lease_duration,
        data: data,
        wrap_info: wrap_info,
        warnings: warnings,
        auth: auth
      }
    end
  end

  defmodule ErrorResponse do
    defstruct [:httpstatus, :errors]

    def from_resp(%{status: status, body: %{"errors" => errors}}) do
      %__MODULE__{httpstatus: status, errors: errors}
    end
  end

  def parse_response({:ok, %{status: status} = resp}) when status >= 400,
    do: {:ok, ErrorResponse.from_resp(resp)}

  def parse_response({:ok, %{status: status} = resp}), do: {:ok, SuccessResponse.from_resp(resp)}

  def parse_response(not_ok), do: not_ok

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
    |> parse_response()
  end

  def write(client, mount, path, params) do
    client
    |> Tesla.post("/v1/#{mount}/#{path}", params)
    |> parse_response()
  end

  def delete(client, mount, path) do
    client
    |> Tesla.request(url: "/v1/#{mount}/#{path}", method: "DELETE")
    |> parse_response()
  end

  def list(client, mount, path) do
    client
    |> Tesla.request(url: "/v1/#{mount}/#{path}", method: "LIST")
    |> parse_response()
  end
end
