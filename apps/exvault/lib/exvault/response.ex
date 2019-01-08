defmodule ExVault.Response do
  @moduledoc """
  Structs for the most common Vault API response formats.

  Vault does have a handful of APIs with responses that don't fit any of these,
  but the documentation isn't particularly clear about what those are.
  """

  defmodule Error do
    @moduledoc """
    Vault API error response. This represents an HTTP 4xx/5xx response.
    """

    defstruct [:status, :errors]

    @type t :: %__MODULE__{
            status: integer,
            errors: [String.t()]
          }

    def from_resp(%{status: status, body: %{"errors" => errors}}) do
      %__MODULE__{status: status, errors: errors}
    end
  end

  defmodule Success do
    @moduledoc """
    Vault API success response. This represents an HTTP 2xx response.

    Usually, the `logical` field will contain a `Response.Logical` struct.
    """

    alias ExVault.Response.Logical

    defstruct [:status, :logical, :body]

    @type t :: %__MODULE__{
            status: integer,
            body: %{} | String.t(),
            logical: Logical.t() | nil
          }

    def from_resp(%{status: status, body: body}) do
      %__MODULE__{
        status: status,
        body: body,
        logical: Logical.from_body(body)
      }
    end
  end

  defmodule Logical do
    @moduledoc """
    Vault API "logical" response. Most Vault APIs return one of these.
    """

    defstruct [
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

    def from_body(%{
          "request_id" => request_id,
          "lease_id" => lease_id,
          "renewable" => renewable,
          "lease_duration" => lease_duration,
          "data" => data,
          "wrap_info" => wrap_info,
          "warnings" => warnings,
          "auth" => auth
        }) do
      %__MODULE__{
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

    def from_body(_), do: nil
  end

  def parse_response({:ok, %{status: status} = resp}) when status >= 400,
    do: {:ok, Error.from_resp(resp)}

  def parse_response({:ok, resp}), do: {:ok, Success.from_resp(resp)}

  def parse_response(not_ok), do: not_ok
end
