defmodule ExVault.KV2 do
  @moduledoc """
  A wrapper over the basic operations for working with KV v2 data.
  """

  defstruct [:client, :mount]

  @type t :: %__MODULE__{
          client: ExVault.client(),
          mount: String.t()
        }

  @spec new(ExVault.client(), String.t()) :: t()
  def new(client, mount), do: %__MODULE__{client: client, mount: mount}

  # Each of these functions has a variant that operates on a client+mount and
  # another that operates on a backend. The former doesn't have any default
  # args so as to avoid conflicts with the latter.

  # TODO: config

  defmodule GetData do
    @moduledoc """
    `ExVault.KV2.get_data` response struct.
    """

    alias ExVault.Response.{Logical, Success}

    defstruct [:resp, :data, :metadata]

    def mkresp({:ok, resp = %Success{logical: %Logical{data: data}}}),
      do:
        {:ok,
         %__MODULE__{
           resp: resp,
           data: data["data"],
           metadata: data["metadata"]
         }}

    def mkresp(resp), do: resp
  end

  @spec get_data(ExVault.client(), String.t(), String.t(), keyword()) :: ExVault.response()
  def get_data(client, mount, path, opts) do
    query = Keyword.take(opts, [:version])

    client
    |> ExVault.read("#{mount}/data/#{path}", query: query)
    |> GetData.mkresp()
  end

  @spec get_data(t(), String.t(), keyword()) :: ExVault.response()
  def get_data(backend, path, opts \\ []), do: get_data(backend.client, backend.mount, path, opts)

  @spec put_data(ExVault.client(), String.t(), String.t(), map(), keyword()) :: ExVault.response()
  def put_data(client, mount, path, data, opts) do
    # TODO: cas
    ExVault.write(client, "#{mount}/data/#{path}", %{"data" => data})
  end

  @spec put_data(t(), String.t(), map(), keyword()) :: ExVault.response()
  def put_data(backend, path, data, opts \\ []),
    do: put_data(backend.client, backend.mount, path, data, opts)

  # TODO: delete

  # TODO: undelete

  # TODO: destroy

  # TODO: list

  # TODO: read metadata

  # TODO: update metadata

  # TODO: delete metadata
end
