defmodule ExVault.KV2Test do
  use ExUnit.Case

  alias ExVault.KV2

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

  setup [:client_any, :kvv2_backend]

  defp kvv2_backend(%{fake_vault: _}) do
    FakeVault.add_backend("kvv2", FakeVault.KVv2)
  end

  defp kvv2_backend(%{client: client}) do
    ExVault.write(client, "sys/mounts", "kvv2", %{"type" => "kv", "options" => %{"version" => 2}})
    on_exit(fn -> ExVault.delete(client, "sys/mounts", "kvv2") end)
    :ok
  end

  defp assert_status(status, {:ok, resp}) do
    assert resp.status == status
    resp
  end

  defp put_version(client, path, value),
    do: assert_status(200, KV2.put_data(client, "kvv2", path, value)).body["data"]

  # TODO: config

  test "put_data new", %{client: client} do
    path = TestHelpers.randkey()
    before = DateTime.utc_now()
    resp = assert_status(200, KV2.put_data(client, "kvv2", path, %{"hello" => "world"}))

    assert %{
             "auth" => nil,
             "data" => %{
               "created_time" => ctime,
               "deletion_time" => "",
               "destroyed" => false,
               "version" => 1
             }
           } = resp.body

    assert_timestamp_since(ctime, before)
  end

  test "put_data update", %{client: client} do
    path = TestHelpers.randkey()
    assert put_version(client, path, %{"hello" => "world"})["version"] == 1
    before = DateTime.utc_now()
    resp = assert_status(200, KV2.put_data(client, "kvv2", path, %{"hello" => "universe"}))

    assert %{
             "auth" => nil,
             "data" => %{
               "created_time" => ctime,
               "deletion_time" => "",
               "destroyed" => false,
               "version" => 2
             }
           } = resp.body

    assert_timestamp_since(ctime, before)
  end

  test "read latest", %{client: client} do
    path = TestHelpers.randkey()

    ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]
    resp = assert_status(200, KV2.get_data(client, "kvv2", path))

    assert %{
             "auth" => nil,
             "data" => %{
               "data" => %{"hello" => "world"},
               "metadata" => %{
                 "created_time" => ^ctime1,
                 "deletion_time" => "",
                 "destroyed" => false,
                 "version" => 1
               }
             }
           } = resp.body

    ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]
    resp = assert_status(200, KV2.get_data(client, "kvv2", path))

    assert %{
             "auth" => nil,
             "data" => %{
               "data" => %{"hello" => "universe"},
               "metadata" => %{
                 "created_time" => ^ctime2,
                 "deletion_time" => "",
                 "destroyed" => false,
                 "version" => 2
               }
             }
           } = resp.body
  end

  test "read version", %{client: client} do
    path = TestHelpers.randkey()

    ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]
    ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]

    resp = assert_status(200, KV2.get_data(client, "kvv2", path, version: 1))

    assert %{
             "auth" => nil,
             "data" => %{
               "data" => %{"hello" => "world"},
               "metadata" => %{
                 "created_time" => ^ctime1,
                 "deletion_time" => "",
                 "destroyed" => false,
                 "version" => 1
               }
             }
           } = resp.body

    resp = assert_status(200, KV2.get_data(client, "kvv2", path, version: 2))

    assert %{
             "auth" => nil,
             "data" => %{
               "data" => %{"hello" => "universe"},
               "metadata" => %{
                 "created_time" => ^ctime2,
                 "deletion_time" => "",
                 "destroyed" => false,
                 "version" => 2
               }
             }
           } = resp.body

    assert_status(404, KV2.get_data(client, "kvv2", path, version: 3))
  end

  test "read missing", %{client: client} do
    path = TestHelpers.randkey()
    resp = assert_status(404, KV2.get_data(client, "kvv2", path))
    assert resp.body == %{"errors" => []}
  end
end
