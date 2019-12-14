defmodule ConnAudit.Auditor do
  use GenServer, restart: :transient

  @lockout Application.get_env(:conn_audit, Auditing) |> Keyword.get(:lockout)
  @ttl Application.get_env(:conn_audit, Auditing) |> Keyword.get(:ttl)

  alias ConnAudit.AuditRegistry

  def start_link(audit_token) do
    GenServer.start_link(
      __MODULE__,
      {:ok, audit_token},
      name: {:via, Registry, {AuditRegistry, audit_token}}
    )
  end

  def start_auditor(audit_token) do
    DynamicSupervisor.start_child(ConnAudit.DynamicSupervisor, {__MODULE__, audit_token})
  end

  defp name_via_registry(audit_token) do
    case Registry.lookup(AuditRegistry, audit_token) do
      [] ->
        start_auditor(audit_token)
        {:via, Registry, {AuditRegistry, audit_token}}

      _ ->
        {:via, Registry, {AuditRegistry, audit_token}}
    end
  end

  # ## Client API
  def check(audit_token), do: name_via_registry(audit_token) |> GenServer.call(:check)

  def fail(audit_token), do: name_via_registry(audit_token) |> GenServer.cast(:fail)

  def succeed(audit_token), do: name_via_registry(audit_token) |> GenServer.cast(:succeed)

  # ## Internal API
  def init({:ok, auditor_token}) do
    :telemetry.execute(
      [:conn_audit, :audit, :start],
      %{token: auditor_token},
      %{}
    )

    {:ok, {auditor_token, 0}, @ttl}
  end

  def handle_info(:timeout, {token, attempts}) do
    :telemetry.execute(
      [:conn_audit, :audit, :timeout],
      %{attempts: attempts},
      %{token: token}
    )

    {:stop, :normal, @ttl}
  end

  def handle_call(:check, _from, {_, attempts} = state) when attempts < @lockout do
    {:reply, :pass, state, @ttl}
  end

  def handle_call(:check, _from, {token, attempts} = state) when attempts >= @lockout do
    :telemetry.execute(
      [:conn_audit, :audit, :lockout],
      %{attempts: attempts},
      %{token: token}
    )

    {:reply, :fail, state, @ttl}
  end

  def handle_cast(:succeed, {token, attempts}) do
    :telemetry.execute(
      [:conn_audit, :audit, :success],
      %{attempts: attempts},
      %{token: token}
    )

    {:stop, :normal, @ttl}
  end

  def handle_cast(:fail, {token, attempts}) do
    new_attempts = attempts + 1

    :telemetry.execute(
      [:conn_audit, :audit, :failure],
      %{attempts: new_attempts},
      %{token: token}
    )

    {:noreply, {token, new_attempts}, @ttl}
  end
end
