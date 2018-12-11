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

    import ExUnit.Assertions

    defp assert_env(var) do
      value = System.get_env(var)
      assert value != nil, "#{var} environment variable not set"
      value
    end

    def client_external(_ctx) do
      baseurl = assert_env("VAULT_ADDR")
      token = assert_env("VAULT_ROOT_TOKEN")
      client = ExVault.new(baseurl: baseurl, token: token)
      {:ok, client: client}
    end

    def client_fake(_ctx) do
      TestHelpers.setup_apps([:plug_cowboy, :plug, :cowboy])
      {:ok, fake_vault} = start_supervised(FakeVault.Supervisor)
      client = ExVault.new(baseurl: FakeVault.base_url(), token: "faketoken")
      {:ok, fake_vault: fake_vault, client: client}
    end

    def client_any(ctx) do
      if System.get_env("EXVAULT_TEST_EXTERNAL") in [nil, "0"] do
        client_fake(ctx)
      else
        client_external(ctx)
      end
    end
  end
end

ExUnit.start()
