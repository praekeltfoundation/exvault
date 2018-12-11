defmodule ExVault.KV2 do
  # TODO: config

  def get_data(client, mount, path, opts \\ []) do
    query =
      case Keyword.get(opts, :version) do
        nil -> []
        v -> [version: v]
      end

    ExVault.read(client, mount, "data/" <> path, query: query)
  end

  def put_data(client, mount, path, data, opts \\ []) do
    # TODO: cas
    ExVault.write(client, mount, "data/" <> path, %{"data" => data})
  end

  # TODO: delete

  # TODO: undelete

  # TODO: destroy

  # TODO: list

  # TODO: read metadata

  # TODO: update metadata

  # TODO: delete metadata
end
