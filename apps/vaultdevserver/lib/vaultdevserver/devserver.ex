defmodule VaultDevServer.DevServer do
  @moduledoc """
  Runs a Vault dev server in a subprocess for test purposes.
  """

  use GenServer

  @vault_first_line "==> Vault server configuration:"
  @vault_started_line "==> Vault server started! Log data will stream in below:"

  defmodule State do
    @moduledoc false

    defstruct [:port, :output_buf, :output_lines, :api_addr, :root_token]

    def new(port),
      do: %__MODULE__{
        port: port,
        output_buf: "",
        output_lines: [],
        api_addr: nil,
        root_token: nil
      }

    def add_output(state, {lines, buf}) do
      %__MODULE__{state | output_buf: buf, output_lines: lines ++ state.output_lines}
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def api_addr(ds), do: GenServer.call(ds, :api_addr)

  def root_token(ds), do: GenServer.call(ds, :root_token)

  defp splt(buf), do: String.split(buf, "\n", parts: 2)

  defp collect_lines(lines, [buf]), do: {lines, buf}
  defp collect_lines(lines, [line, buf]), do: collect_lines([line | lines], splt(buf))

  def collect_lines(buf), do: collect_lines([], splt(buf))

  defp process_output(state, data) do
    {lines, buf} = collect_lines(state.output_buf <> data)
    state = State.add_output(state, {lines, buf})

    lines
    |> Enum.reverse()
    |> Enum.each(&send(self(), {:line, &1}))

    state
  end

  defp receive_first_line(state) do
    port = state.port

    receive do
      {^port, {:data, data}} ->
        state |> process_output(data) |> receive_first_line()

      {:line, line} ->
        {state, line}
    after
      5000 -> {:error, "Timed out waiting for Vault to start"}
    end
  end

  defp collect_config(state) do
    port = state.port

    receive do
      {^port, {:data, data}} ->
        state |> process_output(data) |> collect_config()

      {:line, @vault_started_line} ->
        state

      {:line, line} ->
        state =
          case String.trim(line) do
            "Api Address: " <> addr -> %State{state | api_addr: addr}
            "Root Token: " <> token -> %State{state | root_token: token}
            _ -> state
          end

        collect_config(state)
    after
      5000 -> {:error, "Timed out waiting for Vault to start"}
    end
  end

  defp wait_for_startup(state) do
    case receive_first_line(state) do
      {:error, err} -> {:error, err}
      {state, @vault_first_line} -> collect_config(state)
      {_state, line} -> {:error, "Unexpected Vault output: #{line}"}
    end
  end

  defp vault_path_default do
    case System.get_env("VAULT_PATH") do
      nil -> "vault"
      vault_path -> vault_path
    end
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)
    root_token = Keyword.get(opts, :root_token, "root")
    vault_path = Keyword.get(opts, :vault_path, vault_path_default())
    extra_args = Keyword.get(opts, :extra_args, [])
    cmd = System.find_executable(vault_path)
    args = ["server", "-dev", "-dev-root-token-id=#{root_token}" | extra_args]
    port = Port.open({:spawn_executable, cmd}, [:binary, :stderr_to_stdout, args: args])

    case wait_for_startup(State.new(port)) do
      {:error, err} -> {:stop, err}
      state -> {:ok, state}
    end
  end

  @impl GenServer
  def terminate(_reason, state) do
    case Port.info(state.port) do
      nil -> nil
      info -> System.cmd("kill", ["#{info[:os_pid]}"])
    end
  end

  @impl GenServer
  def handle_call(:api_addr, _from, state), do: {:reply, state.api_addr, state}
  def handle_call(:root_token, _from, state), do: {:reply, state.root_token, state}

  @impl GenServer
  def handle_info({_port, {:data, data}}, state) do
    state = process_output(state, data)
    {:noreply, state}
  end

  def handle_info({:line, _line}, state) do
    {:noreply, state}
  end
end
