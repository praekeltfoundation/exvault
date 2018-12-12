defmodule ExVault.KV1 do
  @moduledoc """
  A very thin wrapper over the basic operations for working with KV v1 data.
  """

  # This is the thinnest of wrappers around the basic operations.
  def read(client, mount, path), do: ExVault.read(client, mount, path)
  def write(client, mount, path, params), do: ExVault.write(client, mount, path, params)
  def delete(client, mount, path), do: ExVault.delete(client, mount, path)
  def list(client, mount, path), do: ExVault.list(client, mount, path)
end
