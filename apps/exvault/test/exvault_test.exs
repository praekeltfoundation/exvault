defmodule ExVaultTest do
  use ExUnit.Case

  alias ExVault.Response.Error

  import TestHelpers.Setup, [:client_apps, :devserver, :client]

  setup_all [:client_apps, :devserver]

  describe "basic operations" do
    # This uses KVv1, which supports all basic operations.

    setup [:client, :kvv1_backend]

    defp kvv1_backend(%{client: client}) do
      ExVault.write(client, "sys/mounts", "kvv1", %{"type" => "kv"})
      on_exit(fn -> ExVault.delete(client, "sys/mounts", "kvv1") end)
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

    defp writekey(client, path, value),
      do: assert_status(204, ExVault.write(client, "kvv1", path, value))

    defp assert_present(client, path),
      do: assert_status(200, ExVault.read(client, "kvv1", path))

    defp assert_present(client, path, data),
      do: assert(assert_present(client, path).logical.data == data)

    defp assert_absent(client, path),
      do: assert_status(404, ExVault.read(client, "kvv1", path))

    test "write", %{client: client} do
      path = TestHelpers.randkey()
      assert_status(204, ExVault.write(client, "kvv1", path, %{"hello" => "world"}))
      assert_present(client, path, %{"hello" => "world"})
    end

    test "write PUT", %{client: client} do
      # FIXME: This tests FakeVault rather than the client.
      path = TestHelpers.randkey()

      assert {:ok, %{status: 204, body: ""}} =
               Tesla.put(client, "/v1/kvv1/#{path}", %{"hello" => "world"})

      assert_present(client, path, %{"hello" => "world"})
    end

    test "read", %{client: client} do
      path = TestHelpers.randkey()
      writekey(client, path, %{"hello" => "world"})
      resp = assert_status(200, ExVault.read(client, "kvv1", path))
      assert resp.logical.data == %{"hello" => "world"}
    end

    test "read missing", %{client: client} do
      path = TestHelpers.randkey()
      assert_error(404, [], ExVault.read(client, "kvv1", path))
    end

    test "delete", %{client: client} do
      path = TestHelpers.randkey()
      writekey(client, path, %{"hello" => "world"})
      assert_present(client, path)
      assert_status(204, ExVault.delete(client, "kvv1", path))
      assert_absent(client, path)
    end

    test "delete missing", %{client: client} do
      path = TestHelpers.randkey()
      assert_absent(client, path)
      assert_status(204, ExVault.delete(client, "kvv1", path))
      assert_absent(client, path)
    end

    test "list all", %{client: client} do
      path = TestHelpers.randkey()
      writekey(client, path, %{"hello" => "world"})
      resp = assert_status(200, ExVault.list(client, "kvv1", ""))
      assert resp.logical.data == %{"keys" => [path]}
    end

    test "list subfolder", %{client: client} do
      path = TestHelpers.randkey()
      writekey(client, "#{path}/k2", %{"goodbye" => "moon"})
      writekey(client, "#{path}/k1", %{"hello" => "world"})
      writekey(client, "#{path}/k3/c1", %{"blue" => "sky"})
      writekey(client, "#{path}/k3/c2", %{"green" => "field"})
      resp = assert_status(200, ExVault.list(client, "kvv1", path))
      assert %{"keys" => keys} = resp.logical.data
      assert Enum.sort(keys) == ["k1", "k2", "k3/"]
    end

    test "list missing", %{client: client} do
      path = TestHelpers.randkey()
      assert_error(404, [], ExVault.list(client, "kvv1", path))
    end
  end
end
