defmodule ConnAudit.MixProject do
  use Mix.Project

  def project do
    [
      app: :conn_audit,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "ConnAudit",
      source_url: "https://github.com/adigitalmonk/conn_audit",
      homepage_url: "https://github.com/adigitalmonk/conn_audit",
      docs: [
        main: "ConnAudit",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ConnAudit.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.8"},
      {:telemetry, "~> 0.4.1"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
