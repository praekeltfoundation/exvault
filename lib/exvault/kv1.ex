defmodule ExVault.KV1 do
  @moduledoc """
  A very thin wrapper over the basic operations for working with KV v1 data.

  Construct a *backend*--a client paired with the mount path for the `kv`
  version 1 secrets engine it interacts with--using the `ExVault.KV1.new/2`
  function.

  Each of the operations in this module have a variant that operates on a client
  and mount path, and another that operates on a backend.

  See the [Vault documentation](https://www.vaultproject.io/docs/secrets/kv/kv-v1.html)
  for the secrets engine.
  """

  defstruct [:client, :mount]

  @type t :: %__MODULE__{
          client: ExVault.client(),
          mount: String.t()
        }

  @doc """
  Create a new backend for the `kv` version 1 secrets engine.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
  """
  @spec new(ExVault.client(), String.t()) :: t()
  def new(client, mount), do: %__MODULE__{client: client, mount: mount}

  @doc """
  Read the value of a key.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
   * `path` the path to the key in the secrets engine.
  """
  @spec read(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def read(client, mount, path), do: ExVault.read(client, "#{mount}/#{path}")

  @doc """
  Read the value of a key.

  Params:
   * `backend` the `ExVault.KV1` backend.
   * `path` the path to the key in the secrets engine.
  """
  @spec read(t(), String.t()) :: ExVault.response()
  def read(backend, path), do: read(backend.client, backend.mount, path)

  @doc """
  Write the value of a key.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
   * `path` the path to the key in the secrets engine.
   * `data` the data to write as a map of string keys to string values.
  """
  @spec write(ExVault.client(), String.t(), String.t(), %{String.t() => String.t()}) ::
          ExVault.response()
  def write(client, mount, path, data), do: ExVault.write(client, "#{mount}/#{path}", data)

  @doc """
  Write the value of a key.

  Params:
   * `backend` the `ExVault.KV1` backend.
   * `path` the path to the key in the secrets engine.
   * `data` the data to write as a map of string keys to string values.
  """
  @spec write(t(), String.t(), any()) :: ExVault.response()
  def write(backend, path, data), do: write(backend.client, backend.mount, path, data)

  @doc """
  Delete a key.

  Params:
   * `client` the `ExVault` client.
   * `mount` the mount path for the `kv` secrets engine.
   * `path` the path to the key in the secrets engine.
  """
  @spec delete(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def delete(client, mount, path), do: ExVault.delete(client, "#{mount}/#{path}")

  @doc """
  Delete a key.

  Params:
   * `backend` the `ExVault.KV1` backend.
   * `path` the path to the key in the secrets engine.
  """
  @spec delete(t(), String.t()) :: ExVault.response()
  def delete(backend, path), do: delete(backend.client, backend.mount, path)

  @doc """
  List the keys.

  Params:
   * `client` the ExVault client.
   * `mount` the mount path for the `kv` secrets engine.
   * `path` the path to the key or key prefix in the secrets engine.
  """
  @spec list(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def list(client, mount, path), do: ExVault.list(client, "#{mount}/#{path}")

  @doc """
  List the keys.

  Params:
   * `backend` the `ExVault.KV1` backend.
   * `path` the path to the key or key prefix in the secrets engine.
  """
  @spec list(t(), String.t()) :: ExVault.response()
  def list(backend, path), do: list(backend.client, backend.mount, path)
end
