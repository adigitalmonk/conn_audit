defmodule ConnAudit.Auditing.Auditor do
  @moduledoc false

  use GenServer, restart: :transient
  # import ConnAudit.Server

  alias ConnAudit.Auditing.Registry, as: AuditRegistry
  alias ConnAudit.Auditing.State

  @lockout Application.get_env(:conn_audit, Auditing) |> Keyword.get(:lockout)
  @ttl Application.get_env(:conn_audit, Auditing) |> Keyword.get(:ttl)

  @check_pass :pass
  @check_fail :fail

  @doc false
  def start_link(identifier) do
    GenServer.start_link(
      __MODULE__,
      {:ok, identifier},
      name: {:via, Registry, {AuditRegistry, identifier}}
    )
  end

  @doc false
  def start_auditor(identifier) do
    DynamicSupervisor.start_child(ConnAudit.DynamicSupervisor, {__MODULE__, identifier})
  end

  @doc false
  defp name_as_registered(identifier) do
    case registered(identifier) do
      [] ->
        start_auditor(identifier)
        {:via, Registry, {AuditRegistry, identifier}}

      _ ->
        {:via, Registry, {AuditRegistry, identifier}}
    end
  end

  @doc false
  defp registered(identifier) do
    Registry.lookup(AuditRegistry, identifier)
  end

  ## Client API
  @doc false
  def check(identifier) do
    case registered(identifier) do
      [] ->
        @check_pass

      _ ->
        identifier
        |> name_as_registered()
        |> GenServer.call(:check)
    end
  end

  @doc false
  def fail(identifier), do: identifier |> name_as_registered() |> GenServer.cast(:fail)

  @doc false
  def succeed(identifier), do: identifier |> name_as_registered() |> GenServer.cast(:succeed)

  @doc false
  def attempts(identifier) do
    case registered(identifier) do
      [] ->
        0

      _ ->
        identifier
        |> name_as_registered()
        |> GenServer.call(:attempts)
    end
  end

  ## Internal API
  @doc false
  def init({:ok, identifier}) do
    :telemetry.execute(
      [:conn_audit, :audit, :start],
      %{identifier: identifier},
      %{timestamp: DateTime.utc_now()}
    )

    {:ok, State.new(identifier), @ttl}
  end

  @doc false
  def handle_info(:timeout, %State{identifier: identifier, attempts: attempts}) do
    :telemetry.execute(
      [:conn_audit, :audit, :timeout],
      %{identifier: identifier, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:stop, :normal, nil}
  end

  @doc false
  def handle_continue(:adjust_ttl, %State{last: last} = state) do
    adjusted_ttl =
      DateTime.add(last, @ttl, :millisecond)
      |> DateTime.diff(DateTime.utc_now(), :millisecond)

    {:noreply, state, adjusted_ttl}
  end

  @doc false
  def handle_call(:attempts, _from, %State{attempts: attempts} = state) do
    {:reply, attempts, state, {:continue, :adjust_ttl}}
  end

  @doc false
  def handle_call(:check, _from, %State{attempts: attempts} = state) when attempts < @lockout do
    {:reply, @check_pass, state, {:continue, :adjust_ttl}}
  end

  @doc false
  def handle_call(:check, _from, %State{identifier: identifier, attempts: attempts} = state)
      when attempts >= @lockout do

    :telemetry.execute(
      [:conn_audit, :audit, :lockout],
      %{identifier: identifier, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:reply, @check_fail, state, {:continue, :adjust_ttl}}
  end

  @doc false
  def handle_cast(:succeed, %State{identifier: identifier, attempts: attempts}) do
    :telemetry.execute(
      [:conn_audit, :audit, :success],
      %{identifier: identifier, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:stop, :normal, nil}
  end

  @doc false
  def handle_cast(:fail, %State{} = state) do
    state = %State{identifier: identifier, attempts: attempts} = State.fail(state)

    :telemetry.execute(
      [:conn_audit, :audit, :failure],
      %{identifier: identifier, attempts: attempts},
      %{timestamp: DateTime.utc_now()}
    )

    {:noreply, state, @ttl}
  end
end
