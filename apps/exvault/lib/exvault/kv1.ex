defmodule ExVault.KV1 do
  @moduledoc """
  A very thin wrapper over the basic operations for working with KV v1 data.
  """

  @spec read(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def read(client, mount, path), do: ExVault.read(client, mount, path)

  @spec write(ExVault.client(), String.t(), String.t(), any()) :: ExVault.response()
  def write(client, mount, path, params), do: ExVault.write(client, mount, path, params)

  @spec delete(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def delete(client, mount, path), do: ExVault.delete(client, mount, path)

  @spec list(ExVault.client(), String.t(), String.t()) :: ExVault.response()
  def list(client, mount, path), do: ExVault.list(client, mount, path)
end
