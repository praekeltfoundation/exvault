defmodule FakeVault.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, args) do
    FakeVault.Supervisor.start_link(args, [])
  end
end
