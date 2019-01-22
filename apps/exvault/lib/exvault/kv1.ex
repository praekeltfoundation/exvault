defmodule ExVault.KV1 do
  @moduledoc """
  A very thin wrapper over the basic operations for working with KV v1 data.
  """

  defstruct [:client, :mount]

  @type t :: %__MODULE__{
          client: ExVault.client(),
          mount: String.t()
        }

  @spec new(ExVault.client(), String.t()) :: t()
  def new(client, mount), do: %__MODULE__{client: client, mount: mount}

  # Each of these functions has a variant that operates on a client+mount and
  # another that operates on a backend.

  @spec read(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def read(client, mount, path), do: ExVault.read(client, "#{mount}/#{path}")

  @spec read(t(), String.t()) :: ExVault.response()
  def read(backend, path), do: read(backend.client, backend.mount, path)

  @spec write(ExVault.client(), String.t(), String.t(), any()) :: ExVault.response()
  def write(client, mount, path, params), do: ExVault.write(client, "#{mount}/#{path}", params)

  @spec write(t(), String.t(), any()) :: ExVault.response()
  def write(backend, path, params), do: write(backend.client, backend.mount, path, params)

  @spec delete(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def delete(client, mount, path), do: ExVault.delete(client, "#{mount}/#{path}")

  @spec delete(t(), String.t()) :: ExVault.response()
  def delete(backend, path), do: delete(backend.client, backend.mount, path)

  @spec list(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def list(client, mount, path), do: ExVault.list(client, "#{mount}/#{path}")

  @spec list(t(), String.t()) :: ExVault.response()
  def list(backend, path), do: list(backend.client, backend.mount, path)
end
