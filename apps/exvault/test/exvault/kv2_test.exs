defmodule ExVault.KV2Test do
  use ExUnit.Case

  alias ExVault.KV2
  alias ExVault.Response.{Error, Logical, Success}

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
    do: assert_status(200, KV2.put_data(client, "kvv2", path, value, [])).logical.data

  defp assert_get_data(resp, data: data, metadata: metadata) do
    logicaldata = %{"data" => data, "metadata" => metadata}

    assert {:ok,
            %KV2.GetData{
              data: ^data,
              metadata: ^metadata,
              resp: %Success{logical: %Logical{data: ^logicaldata}}
            }} = resp
  end

  describe "backend" do
    test "new", %{client: client} do
      assert KV2.new(client, "mount") == %KV2{client: client, mount: "mount"}
      assert KV2.new(client, "hill") == %KV2{client: client, mount: "hill"}
    end

    # TODO: config

    test "put_data new", %{client: client} do
      path = TestHelpers.randkey()
      backend = KV2.new(client, "kvv2")
      before = DateTime.utc_now()
      resp = assert_status(200, KV2.put_data(backend, path, %{"hello" => "world"}))

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
      backend = KV2.new(client, "kvv2")
      assert put_version(client, path, %{"hello" => "world"})["version"] == 1
      before = DateTime.utc_now()
      resp = assert_status(200, KV2.put_data(backend, path, %{"hello" => "universe"}))

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
      backend = KV2.new(client, "kvv2")

      ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]

      assert_get_data(KV2.get_data(backend, path),
        data: %{"hello" => "world"},
        metadata: %{
          "created_time" => ctime1,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 1
        }
      )

      ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]

      assert_get_data(KV2.get_data(backend, path),
        data: %{"hello" => "universe"},
        metadata: %{
          "created_time" => ctime2,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 2
        }
      )
    end

    test "read version", %{client: client} do
      path = TestHelpers.randkey()
      backend = KV2.new(client, "kvv2")

      ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]
      ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]

      assert_get_data(KV2.get_data(backend, path, version: 1),
        data: %{"hello" => "world"},
        metadata: %{
          "created_time" => ctime1,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 1
        }
      )

      assert_get_data(KV2.get_data(backend, path, version: 2),
        data: %{"hello" => "universe"},
        metadata: %{
          "created_time" => ctime2,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 2
        }
      )

      assert_error(404, [], KV2.get_data(backend, path, version: 3))
    end

    test "read missing", %{client: client} do
      path = TestHelpers.randkey()
      backend = KV2.new(client, "kvv2")
      assert_error(404, [], KV2.get_data(backend, path))
    end
  end

  describe "client+mount" do
    # TODO: config

    test "put_data new", %{client: client} do
      path = TestHelpers.randkey()
      before = DateTime.utc_now()
      resp = assert_status(200, KV2.put_data(client, "kvv2", path, %{"hello" => "world"}, []))

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
      resp = assert_status(200, KV2.put_data(client, "kvv2", path, %{"hello" => "universe"}, []))

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

      assert_get_data(KV2.get_data(client, "kvv2", path, []),
        data: %{"hello" => "world"},
        metadata: %{
          "created_time" => ctime1,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 1
        }
      )

      ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]

      assert_get_data(KV2.get_data(client, "kvv2", path, []),
        data: %{"hello" => "universe"},
        metadata: %{
          "created_time" => ctime2,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 2
        }
      )
    end

    test "read version", %{client: client} do
      path = TestHelpers.randkey()

      ctime1 = put_version(client, path, %{"hello" => "world"})["created_time"]
      ctime2 = put_version(client, path, %{"hello" => "universe"})["created_time"]

      assert_get_data(KV2.get_data(client, "kvv2", path, version: 1),
        data: %{"hello" => "world"},
        metadata: %{
          "created_time" => ctime1,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 1
        }
      )

      assert_get_data(KV2.get_data(client, "kvv2", path, version: 2),
        data: %{"hello" => "universe"},
        metadata: %{
          "created_time" => ctime2,
          "deletion_time" => "",
          "destroyed" => false,
          "version" => 2
        }
      )

      assert_error(404, [], KV2.get_data(client, "kvv2", path, version: 3))
    end

    test "read missing", %{client: client} do
      path = TestHelpers.randkey()
      assert_error(404, [], KV2.get_data(client, "kvv2", path, []))
    end
  end
end
