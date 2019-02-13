defmodule ExvaultUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      app: :exvault,
      version: "0.1.0-beta.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      name: "ExVault",
      source_url: "https://github.com/praekeltfoundation/exvault"
    ]
  end

  defp aliases do
    [
      # Don't start application for tests.
      test: "test --no-start"
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.json": :test,
      "coveralls.detail": :test,
      credo: :test,
      format: :test,
      release: :prod
    ]
  end

  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:tesla, "~> 1.2"},
      {:jason, "~> 1.0"},
      # We use Hackney because it does cert and hostname verification by
      # default.
      {:hackney, "~> 1.15"},

      # Test deps.
      {:vaultdevserver, "~> 0.1", runtime: false, only: :test},
      {:plug_cowboy, "~> 2.0", only: :test},

      # Dev/test/build tools.
      {:excoveralls, "~> 0.8", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      # Doc tools.
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:inch_ex, "~> 2.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/praekeltfoundation/exvault",
      extras: ["README.md"]
    ]
  end

  defp description do
    "Elixir client library for HashiCorp Vault"
  end

  defp package do
    [
      licenses: ["BSD 3-Clause"],
      links: %{"GitHub" => "https://github.com/praekeltfoundation/exvault"}
    ]
  end

  defp dialyzer do
    [
      # These are most of the optional warnings in the dialyzer docs. We skip
      # :error_handling (because we don't care about functions that only raise
      # exceptions) and two others that are intended for developing dialyzer
      # itself.
      flags: [
        :unmatched_returns,
        # The dialyzer docs indicate that the race condition check can
        # sometimes take a whole lot of time.
        :race_conditions,
        :underspecs
      ]
    ]
  end
end
