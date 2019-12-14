defmodule ConnAudit.MixProject do
  use Mix.Project

  def project do
    [
      app: :conn_audit,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:telemetry, "~> 0.4.1"}
    ]
  end
end
