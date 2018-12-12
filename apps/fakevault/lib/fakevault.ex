defmodule FakeVault do
  @moduledoc """
  A fake Vault API.
  """

  alias FakeVault.{Router, Server}

  def get_name(nil), do: "FakeVault"
  def get_name(name), do: name

  def name_ref(name, suffix), do: :"#{get_name(name)}.#{suffix}"

  def backend_sup(name), do: name_ref(name, "Backends")
  def backend_name(name, mount), do: name_ref(name, "Backend.#{mount}")

  def base_url(name \\ nil), do: "http://localhost:#{Router.port(name)}"

  def add_backend(name \\ nil, mount, module),
    do: Server.add_backend(Server.name_ref(name), mount, module)

  defmodule Request do
    @moduledoc false
    defstruct [:path, :params]

    def from_conn(conn), do: %__MODULE__{path: conn.request_path, params: conn.params}
  end

  defmodule Response do
    @moduledoc false
    defstruct [:body]
  end

  defmodule Handler do
    @moduledoc """
    Request handler behaviour.
    """
    @callback handle(conn :: Plug.Conn.t(), backend_ref :: atom, path_suffix :: String.t()) ::
                Plug.Conn.t()

    defmacro __using__(_opts) do
      quote do
        @behaviour FakeVault.Handler

        alias Plug.Conn
      end
    end
  end
end
