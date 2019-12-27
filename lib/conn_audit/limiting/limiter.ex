defmodule ConnAudit.Limiting.Limiter do
  @moduledoc false

  use GenServer, restart: :transient

  alias ConnAudit.Limiting.Registry, as: LimiterRegistry
  alias ConnAudit.Limiting.State

  @throttle_at 5
  @ttl 5_000

  @permitted :permitted
  @throttled :throttled

  @doc false
  def start_link(identifier) do
    GenServer.start_link(
      __MODULE__,
      {:ok, identifier},
      name: {:via, Registry, {LimiterRegistry, identifier}}
    )
  end

  @doc false
  def start_limiter(identifier) do
    DynamicSupervisor.start_child(ConnAudit.DynamicSupervisor, {__MODULE__, identifier})
  end

  @doc false
  defp name_as_registered(identifier), do: {:via, Registry, {LimiterRegistry, identifier}}

  ## Client API
  @doc false
  def access(identifier), do: identifier |> name_as_registered() |> GenServer.call(:access)

  @doc false
  def reset(identifier), do: identifier |> name_as_registered() |> GenServer.cast(:reset)

  ## Internal API
  @doc false
  def init({:ok, identifier}) do
    :telemetry.execute(
      [:conn_audit, :limiting, :start],
      %{identifier: identifier},
      %{timestamp: DateTime.utc_now()}
    )

    {:ok, State.new(identifier), @ttl}
  end

  @doc false
  def handle_info(:timeout, %State{identifier: token, accessed: accessed}) do
    :telemetry.execute(
      [:conn_audit, :limiting, :timeout],
      %{identifier: token, accessed: accessed},
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
  def handle_call(:accessed, _from, %State{accessed: accessed} = state) do
    {
      :reply,
      accessed,
      state,
      {:continue, :adjust_ttl}
    }
  end

  @doc false
  def handle_call(:access, _from, %State{accessed: accessed} = state) when accessed < @throttle_at do
    {
      :reply,
      @permitted,
      State.accessed(state),
      {:continue, :adjust_ttl}
    }
  end

  @doc false
  def handle_call(:access, _from, %State{identifier: token, accessed: accessed} = state)
      when accessed >= @throttle_at do

    :telemetry.execute(
      [:conn_audit, :limiting, :throttled],
      %{identifier: token, accessed: accessed},
      %{timestamp: DateTime.utc_now()}
    )

    {
      :reply,
      @throttled,
      State.failed_attempt(state),
      {:continue, :adjust_ttl}
    }
  end

  @doc false
  def handle_cast(:reset, %State{identifier: token, accessed: accessed}) do
    :telemetry.execute(
      [:conn_audit, :limiting, :reset],
      %{identifier: token, accessed: accessed},
      %{timestamp: DateTime.utc_now()}
    )

    {:stop, :normal, nil}
  end

end
