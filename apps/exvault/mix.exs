defmodule ExVault.MixProject do
  use Mix.Project

  def project do
    [
      app: :exvault,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      # Don't start application for tests.
      test: "test --no-start"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~>1.2.0"},
      {:jason, ">= 1.0.0"},
      # We use Hackney because it does cert and hostname verification by
      # default.
      {:hackney, "~> 1.14.0"},

      # Test deps.
      {:fakevault, in_umbrella: true, runtime: false}
    ]
  end
end
