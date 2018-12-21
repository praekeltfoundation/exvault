defmodule FakeVault.KVv2 do
  @moduledoc """
  Secrets backend implementation for kv version 2.
  """

  use GenServer
  use FakeVault.Handler
  require Logger

  defmodule Version do
    @moduledoc false

    defstruct [:created, :deleted, :destroyed, :version, :data]

    @type t :: %__MODULE__{
            # ISO-8601 timestamp string
            created: String.t(),
            # ISO-8601 timestamp string
            deleted: String.t(),
            destroyed: boolean,
            version: integer,
            data: %{}
          }

    @spec metadata(t()) :: %{}
    def metadata(v),
      do: %{
        "created_time" => v.created,
        "deletion_time" => v.deleted,
        "destroyed" => v.destroyed,
        "version" => v.version
      }

    @spec new(integer, %{}) :: t()
    def new(version, data) do
      %__MODULE__{
        created: DateTime.utc_now() |> DateTime.to_iso8601(),
        deleted: "",
        destroyed: false,
        version: version,
        data: data
      }
    end

    @spec put([t()], %{}) :: [t()]
    def put([], data), do: [new(1, data)]
    def put([v | _] = versions, data), do: [new(v.version + 1, data) | versions]

    @spec get([t()], integer) :: nil | t()
    def get([], _), do: nil
    def get([v | _], 0), do: v
    def get(versions, v), do: Enum.find(versions, &(&1.version == v))
  end

  #############################################
  # Handler

  @impl FakeVault.Handler
  def handle(conn, backend, path_suffix) do
    [entity, path] = String.split(path_suffix, "/", parts: 2)

    case {conn.method, entity} do
      {"POST", "data"} ->
        handle_post_data(conn, path, backend)

      {"PUT", "data"} ->
        handle_post_data(conn, path, backend)

      {"GET", "data"} ->
        handle_get_data(conn, path, backend)

      _ ->
        _ = Logger.info("Unexpected request in kvv2: #{conn}")
        Conn.send_resp(conn, 405, "")
    end
  end

  defp handle_post_data(conn, path, backend) do
    %{"data" => data} = conn.params
    {:ok, ver} = GenServer.call(backend, {:put_kv_version, path, data})
    send_resp(conn, 200, build_response(Version.metadata(ver)))
  end

  defp handle_get_data(conn, path, backend) do
    {version, ""} = Integer.parse(Map.get(conn.params, "version", "0"))

    case GenServer.call(backend, {:get_kv_version, path, version}) do
      {:ok, nil} ->
        send_resp(conn, 404, %{"errors" => []})

      {:ok, ver} ->
        send_resp(
          conn,
          200,
          build_response(%{"data" => ver.data, "metadata" => Version.metadata(ver)})
        )
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
  def handle_call({:get_kv_version, path, version}, _from, state) do
    ver =
      state.kv_data
      |> Map.get(path, [])
      |> Version.get(version)

    {:reply, {:ok, ver}, state}
  end

  def handle_call({:put_kv_version, path, data}, _from, state) do
    versions =
      state.kv_data
      |> Map.get(path, [])
      |> Version.put(data)

    {:reply, {:ok, hd(versions)}, %State{state | kv_data: Map.put(state.kv_data, path, versions)}}
  end
end
