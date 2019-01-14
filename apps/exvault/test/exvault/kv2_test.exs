defmodule ExVault.KV2Test do
  use ExUnit.Case

  alias ExVault.KV2
  alias ExVault.Response.Error

  import TestHelpers.Setup, [:client_apps, :devserver, :client]

  setup_all [:client_apps, :devserver]
  setup [:client, :kvv2_backend]

  defp assert_timestamp_since(ts, before) do
    now = DateTime.utc_now()
    {:ok, time, 0} = DateTime.from_iso8601(ts)

    assert DateTime.compare(time, before) == :gt,
           "Expected timestamp no earlier than #{before}, got #{ts}"

    assert DateTime.compare(time, now) == :lt,
           "Expected timestamp in the past (as of #{now}), got #{ts}"
  end

  defp kvv2_backend(%{client: client}) do
    ExVault.write(client, "sys/mounts/kvv2", %{"type" => "kv", "options" => %{"version" => 2}})
    on_exit(fn -> ExVault.delete(client, "sys/mounts/kvv2") end)
    :ok
  end

  defp assert_status(status, {:ok, resp}) do
    assert resp.status == status
    resp
  end

  defp assert_error(status, errlist, {:ok, resp}) do
    assert resp == %Error{status: status, errors: errlist}
    resp
  end

  defp put_version(client, path, value),
    do: assert_status(200, KV2.put_data(client, "kvv2", path, value)).logical.data

  # TODO: config

  test "put_data new", %{client: client} do
    path = TestHelpers.randkey()
    before = DateTime.utc_now()
    resp = assert_status(200, KV2.put_data(client, "kvv2", path, %{"hello" => "world"}))

    assert %{
             "created_time" => ctime,
             "deletion_time" => "",
             "destroyed" => false,
             "version" => 1
           } = resp.logical.data

    assert_timestamp_since(ctime, before)
  end

  test "put_data update", %{client: client} do
    path = TestHelpers.randkey()
    assert put_version(client, path, %{"hello" => "world"})["version"] == 1
    before = DateTime.utc_now()
    resp = assert_status(200, KV2.put_data(client, "kvv2", path, %{"hello" => "universe"}))

    assert %{
             "created_time" => ctime,
             "deletion_time" => "",
             "destroyed" => false,
             "version" => 2
           } = resp.logical.data

    assert_timestamp_since(ctime, before)
  end

  test "read latest", %{client: client} do
    path = TestHelpers.randkey()

    ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]
    resp = assert_status(200, KV2.get_data(client, "kvv2", path))

    assert %{
             "data" => %{"hello" => "world"},
             "metadata" => %{
               "created_time" => ^ctime1,
               "deletion_time" => "",
               "destroyed" => false,
               "version" => 1
             }
           } = resp.logical.data

    ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]
    resp = assert_status(200, KV2.get_data(client, "kvv2", path))

    assert %{
             "data" => %{"hello" => "universe"},
             "metadata" => %{
               "created_time" => ^ctime2,
               "deletion_time" => "",
               "destroyed" => false,
               "version" => 2
             }
           } = resp.logical.data
  end

  test "read version", %{client: client} do
    path = TestHelpers.randkey()

    ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]
    ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]

    resp = assert_status(200, KV2.get_data(client, "kvv2", path, version: 1))

    assert %{
             "data" => %{"hello" => "world"},
             "metadata" => %{
               "created_time" => ^ctime1,
               "deletion_time" => "",
               "destroyed" => false,
               "version" => 1
             }
           } = resp.logical.data

    resp = assert_status(200, KV2.get_data(client, "kvv2", path, version: 2))

    assert %{
             "data" => %{"hello" => "universe"},
             "metadata" => %{
               "created_time" => ^ctime2,
               "deletion_time" => "",
               "destroyed" => false,
               "version" => 2
             }
           } = resp.logical.data

    assert_error(404, [], KV2.get_data(client, "kvv2", path, version: 3))
  end

  test "read missing", %{client: client} do
    path = TestHelpers.randkey()
    assert_error(404, [], KV2.get_data(client, "kvv2", path))
  end
end
