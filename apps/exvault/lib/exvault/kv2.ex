defmodule ExVault.KV2 do
  @moduledoc """
  A wrapper over the basic operations for working with KV v2 data.
  """

  # TODO: config

  @spec get_data(ExVault.client(), String.t(), String.t(), keyword()) :: ExVault.response()
  def get_data(client, mount, path, opts \\ []) do
    query =
      case Keyword.get(opts, :version) do
        nil -> []
        v -> [version: v]
      end

    ExVault.read(client, "#{mount}/data/#{path}", query: query)
  end

  @spec put_data(ExVault.client(), String.t(), String.t(), map(), keyword()) :: ExVault.response()
  def put_data(client, mount, path, data, opts \\ []) do
    # TODO: cas
    ExVault.write(client, "#{mount}/data/#{path}", %{"data" => data})
  end

  # TODO: delete

  # TODO: undelete

  # TODO: destroy

  # TODO: list

  # TODO: read metadata

  # TODO: update metadata

  # TODO: delete metadata
end
