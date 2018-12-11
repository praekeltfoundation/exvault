defmodule ExVault.KV1Test do
  use ExUnit.Case

  alias ExVault.KV1
  alias TestHelpers.Setup

  setup_all do
    TestHelpers.setup_apps([:hackney])
  end

  defp assert_timestamp_since(ts, before) do
    now = DateTime.utc_now()
    {:ok, time, 0} = DateTime.from_iso8601(ts)

    assert DateTime.compare(time, before) == :gt,
           "Expected timestamp no earlier than #{before}, got #{ts}"

    assert DateTime.compare(time, now) == :lt,
           "Expected timestamp in the past (as of #{now}), got #{ts}"
  end

  import TestHelpers.Setup, [:client_any]

  setup [:client_any, :kvv1_backend]

  defp kvv1_backend(%{fake_vault: _}) do
    FakeVault.add_backend("kvv1", FakeVault.KVv1)
  end

  defp kvv1_backend(%{client: client}) do
    ExVault.write(client, "sys/mounts", "kvv1", %{"type" => "kv"})
    on_exit(fn -> ExVault.delete(client, "sys/mounts", "kvv1") end)
    :ok
  end

  defp assert_status(status, {:ok, resp}) do
    assert resp.status == status
    resp
  end

  defp writekey(client, path, value),
    do: assert_status(204, KV1.write(client, "kvv1", path, value))

  defp assert_present(client, path),
    do: assert_status(200, KV1.read(client, "kvv1", path))

  defp assert_absent(client, path),
    do: assert_status(404, KV1.read(client, "kvv1", path))

  test "write", %{client: client} do
    path = TestHelpers.randkey()
    resp = assert_status(204, KV1.write(client, "kvv1", path, %{"hello" => "world"}))
    assert resp.body == ""

    assert %{
      "auth" => nil,
      "data" => %{"hello" => "world"}
    } = assert_present(client, path).body
  end

  test "write PUT", %{client: client} do
    # FIXME: This tests FakeVault rather than the client.
    path = TestHelpers.randkey()
    resp = assert_status(204, Tesla.put(client, "/v1/kvv1/#{path}", %{"hello" => "world"}))
    assert resp.body == ""

    assert %{
      "auth" => nil,
      "data" => %{"hello" => "world"}
    } = assert_present(client, path).body
  end

  test "read", %{client: client} do
    path = TestHelpers.randkey()
    writekey(client, path, %{"hello" => "world"})
    resp = assert_status(200, KV1.read(client, "kvv1", path))

    assert %{
      "auth" => nil,
      "data" => %{"hello" => "world"}
    } = resp.body
  end

  test "read missing", %{client: client} do
    path = TestHelpers.randkey()
    resp = assert_status(404, KV1.read(client, "kvv1", path))
    assert resp.body == %{"errors" => []}
  end

  test "delete", %{client: client} do
    path = TestHelpers.randkey()
    writekey(client, path, %{"hello" => "world"})
    assert_present(client, path)
    assert_status(204, KV1.delete(client, "kvv1", path))
    assert_absent(client, path)
  end

  test "delete missing", %{client: client} do
    path = TestHelpers.randkey()
    assert_absent(client, path)
    assert_status(204, KV1.delete(client, "kvv1", path))
    assert_absent(client, path)
  end

  test "list all", %{client: client} do
    path = TestHelpers.randkey()
    writekey(client, path, %{"hello" => "world"})
    resp = assert_status(200, KV1.list(client, "kvv1", ""))

    assert %{
      "auth" => nil,
      "data" => %{"keys" => [path]}
    } = resp.body
  end

  test "list subfolder", %{client: client} do
    path = TestHelpers.randkey()
    writekey(client, "#{path}/k2", %{"goodbye" => "moon"})
    writekey(client, "#{path}/k1", %{"hello" => "world"})
    writekey(client, "#{path}/k3/c1", %{"blue" => "sky"})
    writekey(client, "#{path}/k3/c2", %{"green" => "field"})
    resp = assert_status(200, KV1.list(client, "kvv1", path))
    assert %{"auth" => nil, "data" => %{"keys" => keys}} = resp.body
    assert Enum.sort(keys) == ["k1", "k2", "k3/"]
  end

  test "list missing", %{client: client} do
    path = TestHelpers.randkey()
    assert {:ok, %{status: 404}} = KV1.read(client, "kvv1", path)
    assert {:ok, %{status: 404}} = KV1.list(client, "kvv1", path)
  end
end
