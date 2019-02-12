defmodule VaultDevServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :vaultdevserver,
      version: "0.1.0-beta.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {VaultDevServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # We need ex_doc in each subproject to generate separate docs.
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
