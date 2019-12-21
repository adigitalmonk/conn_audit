defmodule ConnAudit.Auditor do
  @moduledoc false

  use GenServer, restart: :transient

  alias ConnAudit.AuditRegistry
  alias ConnAudit.Audit

  @lockout Application.get_env(:conn_audit, Auditing) |> Keyword.get(:lockout)
  @ttl Application.get_env(:conn_audit, Auditing) |> Keyword.get(:ttl)

  @check_pass :pass
  @check_fail :fail

  @doc false
  def start_link(audit_token) do
    GenServer.start_link(
      __MODULE__,
      {:ok, audit_token},
      name: {:via, Registry, {AuditRegistry, audit_token}}
    )
  end

  @doc false
  def start_auditor(audit_token) do
    DynamicSupervisor.start_child(ConnAudit.DynamicSupervisor, {__MODULE__, audit_token})
  end

  @doc false
  defp name_via_registry(audit_token) do
    case registered(audit_token) do
      [] ->
        start_auditor(audit_token)
        {:via, Registry, {AuditRegistry, audit_token}}

      _ ->
        {:via, Registry, {AuditRegistry, audit_token}}
    end
  end

  @doc false
  defp registered(audit_token) do
    Registry.lookup(AuditRegistry, audit_token)
  end

  ## Client API
  @doc false
  def check(audit_token) do
    case registered(audit_token) do
      [] ->
        @check_pass

      _ ->
        name_via_registry(audit_token)
        |> GenServer.call(:check)
    end
  end

  @doc false
  def fail(audit_token), do: name_via_registry(audit_token) |> GenServer.cast(:fail)

  @doc false
  def succeed(audit_token), do: name_via_registry(audit_token) |> GenServer.cast(:succeed)

  ## Internal API
  @doc false
  def init({:ok, auditor_token}) do
    :telemetry.execute(
      [:conn_audit, :audit, :start],
      %{token: auditor_token},
      %{timestamp: DateTime.utc_now()}
    )

    {:ok,
     %Audit{
       token: auditor_token,
       attempts: 0,
       last: nil
     }, @ttl}
  end

  @doc false
  def handle_info(:timeout, %Audit{token: token, attempts: attempts}) do
    :telemetry.execute(
      [:conn_audit, :audit, :timeout],
      %{token: token, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:stop, :normal, nil}
  end

  @doc false
  def handle_continue(:adjust_ttl, %Audit{last: last} = state) do
    adjusted_ttl =
      DateTime.add(last, @ttl, :millisecond)
      |> DateTime.diff(DateTime.utc_now(), :millisecond)

    {:noreply, state, adjusted_ttl}
  end

  @doc false
  def handle_call(:check, _from, %Audit{attempts: attempts} = state) when attempts < @lockout do
    {:reply, @check_pass, state, {:continue, :adjust_ttl}}
  end

  @doc false
  def handle_call(:check, _from, %Audit{token: token, attempts: attempts} = state)
      when attempts >= @lockout do
    :telemetry.execute(
      [:conn_audit, :audit, :lockout],
      %{token: token, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:reply, @check_fail, state, {:continue, :adjust_ttl}}
  end

  @doc false
  def handle_cast(:succeed, {token, attempts}) do
    :telemetry.execute(
      [:conn_audit, :audit, :success],
      %{token: token, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:stop, :normal, @ttl}
  end

  @doc false
  def handle_cast(:fail, %Audit{token: token, attempts: attempts}) do
    new_attempts = attempts + 1

    :telemetry.execute(
      [:conn_audit, :audit, :failure],
      %{token: token, attempts: new_attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:noreply,
     %Audit{
       token: token,
       attempts: new_attempts,
       last: DateTime.utc_now()
     }, @ttl}
  end
end
