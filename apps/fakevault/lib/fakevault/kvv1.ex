defmodule FakeVault.KVv1 do
  @moduledoc """
  Secrets backend implementation for kv version 1.
  """

  use GenServer
  use FakeVault.Handler
  require Logger

  #############################################
  # Handler

  @impl FakeVault.Handler
  def handle(conn, backend, path) do
    case conn.method do
      "PUT" ->
        handle_post(conn, path, backend)

      "POST" ->
        handle_post(conn, path, backend)

      "GET" ->
        handle_get(conn, path, backend)

      "DELETE" ->
        handle_delete(conn, path, backend)

      "LIST" ->
        handle_list(conn, path, backend)

      _ ->
        _ = Logger.info("Unexpected request in kvv1: #{conn}")
        Conn.send_resp(conn, 405, "")
    end
  end

  defp handle_post(conn, path, backend) do
    :ok = GenServer.call(backend, {:set_kv_data, path, conn.params})
    Conn.send_resp(conn, 204, "")
  end

  defp handle_get(conn, path, backend) do
    case GenServer.call(backend, {:get_kv_data, path}) do
      {:ok, nil} -> send_resp(conn, 404, %{"errors" => []})
      {:ok, data} -> send_resp(conn, 200, build_response(data))
    end
  end

  defp handle_delete(conn, path, backend) do
    :ok = GenServer.call(backend, {:del_kv_data, path})
    Conn.send_resp(conn, 204, "")
  end

  defp handle_list(conn, path, backend) do
    case GenServer.call(backend, {:list_kv_data, path}) do
      {:ok, []} -> send_resp(conn, 404, %{"errors" => []})
      {:ok, keys} -> send_resp(conn, 200, build_response(%{"keys" => keys}))
    end
  end

  defp send_resp(conn, status, body) do
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(status, Jason.encode!(body))
  end

  defp build_response(data) do
    # NOTE: A bunch of these fields are hardcoded, because we don't really care
    # about their values in tests.
    %{
      "request_id" => "f2f1e2c7-c511-fc0d-7d6e-b7f1143c15d8",
      "lease_id" => "",
      "renewable" => false,
      "lease_duration" => 2764800,
      "data" => data,
      "wrap_info" => nil,
      "warnings" => nil,
      "auth" => nil
    }
  end

  #############################################
  # Server

  def start_link(args) do
    GenServer.start_link(__MODULE__, [], args)
  end

  defmodule State do
    @moduledoc false
    defstruct kv_data: %{}
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:get_kv_data, path}, _from, state) do
    {:reply, {:ok, Map.get(state.kv_data, path)}, state}
  end

  def handle_call({:set_kv_data, path, data}, _from, state) do
    {:reply, :ok, %State{state | kv_data: Map.put(state.kv_data, path, data)}}
  end

  def handle_call({:del_kv_data, path}, _from, state) do
    {:reply, :ok, %State{state | kv_data: Map.drop(state.kv_data, [path])}}
  end

  def handle_call({:list_kv_data, path}, _from, state) do
    path =
      case path do
        "" -> ""
        _ -> path <> "/"
      end

    keys =
      state.kv_data
      |> Map.keys()
      # Filter out all keys that aren't in the subtree we're listing.
      |> Enum.filter(&String.starts_with?(&1, path))
      # Strip the path off the front of the keys we've found.
      |> Enum.map(&String.replace_prefix(&1, path, ""))
      # Truncate subtrees to their top-level path.
      |> Enum.map(&String.replace(&1, ~r[/.*$], "/"))
      # Filter out any duplicate subtree paths.
      |> Enum.uniq()

    {:reply, {:ok, keys}, state}
  end
end
