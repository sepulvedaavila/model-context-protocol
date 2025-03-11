defmodule MCPS.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  defp deps do
    [
      # Shared dependencies
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.0"},
      {:telemetry, "~> 1.2"},

      # Development tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp releases do
    [
      mcps: [
        include_executables_for: [:unix],
        applications: [
          mcps_core: :permanent,
          mcps_management: :permanent,
          mcps_transform: :permanent,
          mcps_gateway: :permanent,
          mcps_telemetry: :permanent,
          mcps_web: :permanent
        ]
      ]
    ]
  end
end
