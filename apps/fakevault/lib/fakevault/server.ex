defmodule FakeVault.Server do
  @moduledoc """
  A fake Vault API.
  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct root_token: nil, name: nil, backends: %{}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: name_ref(args[:name]))
  end

  def name_ref(name), do: FakeVault.name_ref(name, "Server")

  def get_backend(ref, mount), do: GenServer.call(ref, {:get_backend, mount})

  def add_backend(ref, mount, module), do: GenServer.call(ref, {:add_backend, mount, module})

  @impl GenServer
  def init(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    {root_token, _opts} = Keyword.pop(opts, :root_token, "root")
    # {name, root_token} = Keyword.pop(opts, :root_token, UUID.uuid4())
    {:ok, %State{root_token: root_token, name: name}}
  end

  @impl GenServer
  def handle_call({:add_backend, mount, module}, _from, state) do
    case Map.get(state.backends, mount) do
      nil ->
        backend_name = FakeVault.backend_name(state.name, mount)

        {:ok, _} =
          DynamicSupervisor.start_child(
            FakeVault.backend_sup(state.name),
            {module, name: backend_name}
          )

        backend = {module, backend_name}
        {:reply, :ok, %{state | backends: Map.put(state.backends, mount, backend)}}

      existing ->
        {:reply, {:error, "#{existing} already mounted at #{mount}"}, state}
    end
  end

  @impl GenServer
  def handle_call({:get_backend, mount}, _from, state) do
    case Map.get(state.backends, mount) do
      nil -> {:reply, :not_mounted, state}
      {module, backend} -> {:reply, {:ok, module, backend}, state}
    end
  end
end
