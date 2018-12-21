defmodule ExVault.Response do
  defmodule Error do
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
