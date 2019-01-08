defmodule VaultDevServer.DevServerTest do
  use ExUnit.Case

  alias VaultDevServer.DevServer

  test "start" do
    {:ok, ds} = start_supervised(DevServer)
    assert DevServer.api_addr(ds) == "http://127.0.0.1:8200"
    assert DevServer.root_token(ds) == "root"
  end

  test "custom root token" do
    {:ok, ds} = start_supervised({DevServer, [root_token: "tuber"]})
    assert DevServer.api_addr(ds) == "http://127.0.0.1:8200"
    assert DevServer.root_token(ds) == "tuber"
  end

  test "collect_lines" do
    assert DevServer.collect_lines("") == {[], ""}
    assert DevServer.collect_lines("aaa") == {[], "aaa"}
    assert DevServer.collect_lines("aaa\n") == {["aaa"], ""}
    assert DevServer.collect_lines("aaa\nccc\nddd") == {["ccc", "aaa"], "ddd"}
  end
end
