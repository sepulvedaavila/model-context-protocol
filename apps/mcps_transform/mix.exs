defmodule MCPS.Transform.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcps_transform,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MCPS.Transform.Application, []}
    ]
  end

  defp deps do
    [
      {:mcps_core, in_umbrella: true},
      {:nimble_options, "~> 1.0"},
      {:telemetry, "~> 1.2"},
      {:flow, "~> 1.2"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
