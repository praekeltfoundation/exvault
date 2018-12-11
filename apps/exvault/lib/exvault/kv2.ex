defmodule ExVault.KV2 do
  def get_data(client, path, opts \\ []) do
    mountpoint = Keyword.get(opts, :mount, "secret")
    Tesla.get(client, "/v1/#{mountpoint}/data/#{path}")
  end

  def put_data(client, path, data, opts \\ []) do
    mountpoint = Keyword.get(opts, :mount, "secret")
    Tesla.post(client, "/v1/#{mountpoint}/data/#{path}", %{"data" => data})
  end
end
