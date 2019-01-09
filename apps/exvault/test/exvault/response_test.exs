defmodule ExVault.ResponseTest do
  use ExUnit.Case

  alias ExVault.Response.{Error, Success, Logical}

  setup_all do
    TestHelpers.setup_apps([:hackney, :plug_cowboy, :plug, :cowboy])
  end

  defmodule TesterPlug do
    @behaviour Plug

    @impl Plug
    def init(plugfn), do: plugfn

    @impl Plug
    def call(conn, plugfn), do: plugfn.(conn)

    def port, do: :ranch.get_port(:ranch_testerplug)
    def url, do: "http://127.0.0.1:#{port()}/"

    def child_spec(plugfn) do
      opts = [port: 0, ref: :ranch_testerplug]
      {Plug.Cowboy, scheme: :http, plug: {__MODULE__, plugfn}, options: opts}
    end
  end

  defp json_resp(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end

  defp start_tp(plugfn), do: {:ok, _} = start_supervised(TesterPlug.child_spec(plugfn))

  defp mkreq(client), do: ExVault.read(client, "mnt", "path")

  test "protocol error" do
    start_tp(&Plug.Conn.send_resp(&1, 204, ""))
    # Attempting to talk HTTPS to an HTTP server will give us an error.
    client = ExVault.new(baseurl: "https://127.0.0.1:#{TesterPlug.port()}/")

    assert {:error, _} = mkreq(client)
  end

  test "error response" do
    start_tp(&json_resp(&1, 400, %{"errors" => ["err1", "err2"]}))
    client = ExVault.new(baseurl: TesterPlug.url())

    assert {:ok, %Error{status: 400, errors: ["err1", "err2"]}} = mkreq(client)
  end

  test "success 204" do
    start_tp(&Plug.Conn.send_resp(&1, 204, ""))
    client = ExVault.new(baseurl: TesterPlug.url())

    assert {:ok, %Success{status: 204, body: "", logical: nil}} = mkreq(client)
  end

  test "success non-json" do
    start_tp(&Plug.Conn.send_resp(&1, 200, "some stuff"))
    client = ExVault.new(baseurl: TesterPlug.url())

    assert {:ok, %Success{status: 200, body: "some stuff", logical: nil}} = mkreq(client)
  end

  test "success non-logical json" do
    start_tp(&json_resp(&1, 200, %{"some" => "json"}))
    client = ExVault.new(baseurl: TesterPlug.url())

    assert {:ok, %Success{status: 200, body: %{"some" => "json"}, logical: nil}} = mkreq(client)
  end

  test "success logical" do
    body = %{
      "request_id" => "f2f1e2c7-c511-fc0d-7d6e-b7f1143c15d8",
      "lease_id" => "",
      "renewable" => false,
      "lease_duration" => 2_764_800,
      "data" => %{"x" => "1"},
      "wrap_info" => nil,
      "warnings" => nil,
      "auth" => nil
    }

    start_tp(&json_resp(&1, 200, body))
    client = ExVault.new(baseurl: TesterPlug.url())

    assert {:ok, %Success{status: 200, body: ^body, logical: logical}} = mkreq(client)

    assert logical == %Logical{
             request_id: "f2f1e2c7-c511-fc0d-7d6e-b7f1143c15d8",
             lease_id: "",
             renewable: false,
             lease_duration: 2_764_800,
             data: %{"x" => "1"},
             wrap_info: nil,
             warnings: nil,
             auth: nil
           }
  end
end
