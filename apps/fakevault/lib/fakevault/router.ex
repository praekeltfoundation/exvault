defmodule FakeVault.Router do
  @moduledoc """
  HTTP request router for FakeVault.
  """
  use Plug.Builder

  alias FakeVault.Server

  plug(Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason
  )

  def init(opts) do
    %{server: Server.name_ref(opts[:name])}
  end

  def call(conn, %{server: server} = opts) do
    conn = super(conn, opts)
    [_empty, _v1, mount, path_suffix] = String.split(conn.request_path, "/", parts: 4)

    case Server.get_backend(server, mount) do
      :not_mounted -> conn |> send_resp(404, "")
      {:ok, module, backend} -> apply(module, :handle, [conn, backend, path_suffix])
    end
  end

  def child_spec(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name)

    options =
      opts
      |> Keyword.put_new(:port, 0)
      |> Keyword.put_new(:ref, ranch_ref(name))

    Plug.Cowboy.child_spec(scheme: :http, plug: FakeVault.Router, options: options)
  end

  defp ranch_ref(name), do: FakeVault.name_ref(name, "Router")
  def port(name \\ nil), do: :ranch.get_port(ranch_ref(name))
end
