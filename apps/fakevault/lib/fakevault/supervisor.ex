defmodule FakeVault.Supervisor do
  @moduledoc false

  use Supervisor

  alias FakeVault.{Router, Server}

  def start_link(args \\ [], opts) do
    opts = [{:name, name_ref(opts[:name])} | opts]
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def name_ref(name), do: FakeVault.name_ref(name, "Supervisor")

  @impl Supervisor
  def init(args) do
    children = [
      Router.child_spec(args),
      {Server, args},
      {DynamicSupervisor, name: FakeVault.backend_sup(args[:name]), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
