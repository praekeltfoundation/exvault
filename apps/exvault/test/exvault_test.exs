defmodule ExVaultTest do
  use ExUnit.Case

  alias ExVault.KV2

  # test "TODO: make this a real test" do
  #   client = ExVault.new(baseurl: "http://127.0.0.1:8200", token: "root")
  #   assert {:ok, put_resp} = ExVault.kv2_put(client, "foo", %{"hello" => "world"})
  #   IO.inspect({:put, put_resp})
  #   assert {:ok, get_resp} = ExVault.kv2_get(client, "foo")
  #   IO.inspect({:get, get_resp})
  # end

  setup do
    TestHelpers.setup_apps([:hackney])
  end

  defp client_for_external_vault(_ctx) do
    baseurl = System.get_env("VAULT_ADDR")
    assert baseurl != nil, "VAULT_ADDR environment variable not set"
    token = System.get_env("VAULT_ROOT_TOKEN")
    assert token != nil, "VAULT_ROOT_TOKEN environment variable not set"
    client = ExVault.new(baseurl: baseurl, token: token)
    {:ok, client: client}
  end

  defp fake_vault(_ctx) do
    TestHelpers.setup_apps([:plug_cowboy, :plug, :cowboy])
    {:ok, fake_vault} = start_supervised(FakeVault.Supervisor)
    {:ok, fake_vault: fake_vault}
  end

  defp client_for_fake_vault(_ctx) do
    client = ExVault.new(baseurl: FakeVault.base_url(), token: "faketoken")
    {:ok, client: client}
  end

  defp assert_timestamp_since(ts, before) do
    now = DateTime.utc_now()
    {:ok, time, 0} = DateTime.from_iso8601(ts)
    assert DateTime.compare(time, before) == :gt,
      "Expected timestamp no earlier than #{before}, got #{ts}"
    assert DateTime.compare(time, now) == :lt,
      "Expected timestamp in the past (as of #{now}), got #{ts}"
  end

  @spec randkey() :: binary
  defp randkey do
    :crypto.strong_rand_bytes(16)
    |> Base.hex_encode32(padding: false)
  end

  describe "basic operations" do
    # This uses KVv1, which supports all basic operations.

    # setup [:fake_vault, :client_for_fake_vault, :kvv1_backend]
    setup [:client_for_external_vault, :kvv1_backend]

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
      do: assert_status(204, ExVault.write(client, "kvv1", path, value))

    defp assert_present(client, path),
      do: assert_status(200, ExVault.read(client, "kvv1", path))

    defp assert_absent(client, path),
      do: assert_status(404, ExVault.read(client, "kvv1", path))

    test "write", %{client: client} do
      path = randkey()
      resp = assert_status(204, ExVault.write(client, "kvv1", path, %{"hello" => "world"}))
      assert resp.body == ""
    end

    test "read", %{client: client} do
      path = randkey()
      writekey(client, path, %{"hello" => "world"})
      resp = assert_status(200, ExVault.read(client, "kvv1", path))
      assert %{
        "auth" => nil,
        "data" => %{"hello" => "world"}
      } = resp.body
    end

    test "read missing", %{client: client} do
      path = randkey()
      resp = assert_status(404, ExVault.read(client, "kvv1", path))
      assert resp.body == %{"errors" => []}
    end

    test "delete", %{client: client} do
      path = randkey()
      writekey(client, path, %{"hello" => "world"})
      assert_present(client, path)
      assert_status(204, ExVault.delete(client, "kvv1", path))
      assert_absent(client, path)
    end

    test "delete missing", %{client: client} do
      path = randkey()
      assert_absent(client, path)
      assert_status(204, ExVault.delete(client, "kvv1", path))
      assert_absent(client, path)
    end

    test "list all", %{client: client} do
      path = randkey()
      writekey(client, path, %{"hello" => "world"})
      resp = assert_status(200, ExVault.list(client, "kvv1", ""))
      assert %{
        "auth" => nil,
        "data" => %{"keys" => [path]},
      } = resp.body
    end

    test "list subfolder", %{client: client} do
      path = randkey()
      writekey(client, "#{path}/k1", %{"hello" => "world"})
      writekey(client, "#{path}/k2", %{"goodbye" => "moon"})
      writekey(client, "#{path}/k3/child", %{"blue" => "sky"})
      resp = assert_status(200, ExVault.list(client, "kvv1", path))
      assert %{
        "auth" => nil,
        "data" => %{"keys" => ["k1", "k2", "k3/"]},
      } = resp.body
    end

    test "list missing", %{client: client} do
      path = randkey()
      assert {:ok, %{status: 404}} = ExVault.read(client, "kvv1", path)
      assert {:ok, %{status: 404}} = ExVault.list(client, "kvv1", path)
    end
  end

  # describe "KV2" do
  #   setup [:fake_vault, :kvv2_backend, :client_for_fake_vault]
  #   # setup [:client_for_external_vault]

  #   defp kvv2_backend(%{fake_vault: fake_vault}) do
  #     FakeVault.add_backend("secret", FakeVault.KVv2)
  #   end

  #   test "put new data", %{client: client} do
  #     key = randkey()
  #     before = DateTime.utc_now()
  #     assert {:ok, put_resp} = ExVault.KV2.put_data(client, key, %{"hello" => "world"})
  #     assert put_resp.status == 200
  #     assert %{
  #       "auth" => nil,
  #       "data" => %{
  #         "created_time" => creation_time,
  #         "deletion_time" => "",
  #         "destroyed" => false,
  #         "version" => 1
  #       },
  #     } = put_resp.body
  #     assert_timestamp_since(creation_time, before)
  #   end

  #   # test "get", %{client: client} do
  #   #   key = randkey()
  #   #   assert {:ok, %{status: 204}} = ExVault.KV2.put_data(client, key, %{"hello" => "world"})
  #   #   assert {:ok, get_resp} = ExVault.KV2.get_data(client, key, %{"hello" => "world"})
  #   #   IO.inspect({:get, get_resp})
  #   #   assert get_resp.status == 200
  #   #   assert %{
  #   #     "auth" => nil,
  #   #     "data" => %{
  #   #       "data" => %{"hello" => "world"},
  #   #       "metadata" => %{
  #   #         "created_time" => creation_time,
  #   #         "deletion_time" => "",
  #   #         "destroyed" => false,
  #   #         "version" => 1
  #   #       },
  #   #     },
  #   #   } = get_resp.body
  #   # end
  # end
end
