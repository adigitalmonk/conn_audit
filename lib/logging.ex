defmodule Logging do
  # TODO: Document and get rid of this

  def attach_loggers do
    [
      ["audit_success", [:conn_audit, :audit, :success], &__MODULE__.handle_event/4, nil],
      ["audit_failure", [:conn_audit, :audit, :failure], &__MODULE__.handle_event/4, nil],
      ["audit_lockout", [:conn_audit, :audit, :lockout], &__MODULE__.handle_event/4, nil],
      ["audit_timeout", [:conn_audit, :audit, :timeout], &__MODULE__.handle_event/4, nil]
    ]
    |> Enum.each(fn [unique_id, tags, module, opts] ->
      :ok = :telemetry.attach(unique_id, tags, module, opts)
    end)
  end

  def handle_event(
        [:conn_audit, :audit, :success],
        %{token: token, attempts: attempts},
        %{timestamp: timestamp},
        _config
      ) do
    IO.inspect([:success, token, attempts, timestamp])
  end

  def handle_event(
        [:conn_audit, :audit, :failure],
        %{token: token, attempts: attempts},
        %{timestamp: timestamp},
        _config
      ) do
    IO.inspect([:failure, token, attempts, timestamp])
  end

  def handle_event(
        [:conn_audit, :audit, :timeout],
        %{attempts: attempts, token: token},
        %{timestamp: timestamp},
        _config
      ) do
    IO.inspect([:timeout, token, attempts, timestamp])
  end

  def handle_event(
        [:conn_audit, :audit, :lockout],
        %{attempts: attempts, token: token},
        %{timestamp: timestamp},
        _config
      ) do
    IO.inspect([:lockout, token, attempts, timestamp])
  end
end
