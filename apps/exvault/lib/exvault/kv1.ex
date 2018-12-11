defmodule ExVault.KV1 do
  # This is the thinnest of wrappers around the basic operations.
  def read(client, mount, path), do: ExVault.read(client, mount, path)
  def write(client, mount, path, params), do: ExVault.write(client, mount, path, params)
  def delete(client, mount, path), do: ExVault.delete(client, mount, path)
  def list(client, mount, path), do: ExVault.list(client, mount, path)
end
