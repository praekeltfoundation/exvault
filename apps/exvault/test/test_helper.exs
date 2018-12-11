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
end

ExUnit.start()
