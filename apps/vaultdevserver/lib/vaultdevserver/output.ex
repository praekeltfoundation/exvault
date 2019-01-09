defmodule VaultDevServer.Output do
  @moduledoc """
  Collects subprocess output and sends each line to a pid.
  """

  defstruct dest_pid: nil, buf: ""

  def new(dest_pid), do: %__MODULE__{dest_pid: dest_pid}

  defp read_line(buf), do: String.split(buf, "\n", parts: 2)

  defp read_lines(state, [buf]), do: %__MODULE__{state | buf: buf}

  defp read_lines(state, [line, buf]) do
    send(state.dest_pid, {:output_line, line})
    read_lines(state, read_line(buf))
  end

  def collect_lines(state, buf), do: read_lines(state, read_line(state.buf <> buf))
end
