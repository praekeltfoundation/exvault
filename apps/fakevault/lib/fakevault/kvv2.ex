defmodule FakeVault.KVv2 do
  use GenServer
  use FakeVault.Handler

  #############################################
  # Handler

  @impl FakeVault.Handler
  def handle(conn, backend, path_suffix) do
    [entity, path] = String.split(path_suffix, "/", parts: 2)
    case {conn.method, entity} do
      {"POST", "data"} ->
        handle_post_data(conn, path, backend)
      _ ->
        IO.inspect({:kvv2, conn})
        Conn.send_resp(conn, 405, "")
    end
  end

  defp handle_post_data(conn, path, backend) do
    {:ok, data} = GenServer.call(backend, {:set_kv_data, path, conn.params})
    body = build_response(resp_metadata())
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, body)
  end

  defp resp_metadata() do
    # TODO: Use real(ish) metadata or something.
    %{
      "created_time" => "2018-05-29T10:24:30.181952826Z",
      "deletion_time" => "",
      "destroyed" => false,
      "version" => 1
    }
  end

  defp build_response(data) do
    # NOTE: This ignores a bunch of response fields that are poorly
    # documented and that we don't care about anyway. It also uses some
    # hardcoded metadata because we don't care about that either, but
    # probably want it to at least be present.
    Jason.encode!(%{"auth" => nil, "data" => data})
  end

  #############################################
  # Server

  def start_link(args) do
    GenServer.start_link(__MODULE__, [], args)
  end

  defmodule State do
    defstruct kv_data: %{}
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %State{}}
  end

  def handle_call({:get_kv_data, path}, _from, state) do
    {:reply, {:ok, Map.get(state.kv_data, path)}, state}
  end

  def handle_call({:set_kv_data, path, data}, _from, state) do
    {:reply, {:ok, data}, %State{state | kv_data: Map.put(state.kv_data, path, data)}}
  end
end
