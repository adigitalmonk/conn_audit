defmodule ConnAudit.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ConnAudit.AuditRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: ConnAudit.DynamicSupervisor}
    ]

    # TODO: Remove this
    # Logging.attach_loggers()

    opts = [strategy: :one_for_one, name: ConnAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
