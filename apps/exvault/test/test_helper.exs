defmodule TestHelpers do
  import ExUnit.Callbacks

  @doc """
  Start some applications for the duration of a test.

  Best used in `setup` or `setup_all` callbacks.
  """
  def setup_apps(apps) do
    started_apps =
      apps
      |> Stream.map(&start_app/1)
      |> Enum.concat()

    on_exit(fn -> cleanup_apps(started_apps) end)
  end

  defp start_app(app) do
    {:ok, started} = Application.ensure_all_started(app)
    started
  end

  defp cleanup_apps(apps) do
    import ExUnit.CaptureLog
    capture_log(fn -> apps |> Enum.each(&Application.stop/1) end)
  end

  @spec randkey() :: binary
  def randkey do
    :crypto.strong_rand_bytes(16)
    |> Base.hex_encode32(padding: false)
  end

  defmodule Setup do
    @moduledoc """
    Common setup functions.
    """

    alias VaultDevServer.DevServer

    def client_apps(_ctx) do
      TestHelpers.setup_apps([:hackney])
    end

    defp start_devserver do
      {:ok, ds} = start_supervised(DevServer)
      {ds, DevServer.api_addr(ds), DevServer.root_token(ds)}
    end

    def devserver(_ctx) do
      {ds, ds_url, ds_token} = start_devserver()
      {:ok, devserver: ds, address: ds_url, token: ds_token}
    end

    def client(%{address: address, token: token}) do
      client = ExVault.new(address: address, token: token)
      {:ok, client: client}
    end
  end
end

ExUnit.start()
