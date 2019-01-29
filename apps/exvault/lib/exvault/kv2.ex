defmodule ExVault.KV2 do
  @moduledoc """
  A wrapper over the basic operations for working with KV v2 data.

  Construct a *backend*--a client paired with the mount path for the `kv`
  version 2 secrets engine it interacts with--using the `ExVault.KV2.new/2`
  function.

  Each of the operations in this module have a variant that operates on a client
  and mount path, and another that operates on a backend.

  See the [Vault documentation](https://www.vaultproject.io/docs/secrets/kv/kv-v2.html)
  for the secrets engine.
  """

  defstruct [:client, :mount]

  @type t :: %__MODULE__{
          client: ExVault.client(),
          mount: String.t()
        }

  @doc """
  Create a new backend for the `kv` version 2 secrets engine.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
  """
  @spec new(ExVault.client(), String.t()) :: t()
  def new(client, mount), do: %__MODULE__{client: client, mount: mount}

  # TODO: config

  defmodule GetData do
    @moduledoc """
    `ExVault.KV2.get_data` response struct.
    """

    alias ExVault.Response.{Logical, Success}

    defstruct [:resp, :data, :metadata]

    @doc false
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

  @doc """
  Read the value of a key.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
   * `path` the path to the key in the secrets engine.
  """
  @spec get_data(ExVault.client(), String.t(), String.t(), keyword()) :: ExVault.response()
  def get_data(client, mount, path, opts) do
    query = Keyword.take(opts, [:version])

    client
    |> ExVault.read("#{mount}/data/#{path}", query: query)
    |> GetData.mkresp()
  end

  @doc """
  Read the value of a key.

  Params:
   * `backend` the `ExVault.KV2` backend.
   * `path` the path to the key in the secrets engine.
  """
  @spec get_data(t(), String.t(), keyword()) :: ExVault.response()
  def get_data(backend, path, opts \\ []), do: get_data(backend.client, backend.mount, path, opts)

  @doc """
  Write the value of a key.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
   * `path` the path to the key in the secrets engine.
  """
  @spec put_data(ExVault.client(), String.t(), String.t(), map(), keyword()) :: ExVault.response()
  def put_data(client, mount, path, data, opts) do
    # TODO: cas
    ExVault.write(client, "#{mount}/data/#{path}", %{"data" => data})
  end

  @doc """
  Write the value of a key.

  Params:
   * `backend` the `ExVault.KV2` backend.
   * `path` the path to the key in the secrets engine.
  """
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
