defmodule ConnAudit.Auditing.State do
  @moduledoc false
  defstruct [:identifier, :attempts, :last]

  def new(identifier) do
    %__MODULE__{
      identifier: identifier,
      attempts: 0,
      last: nil
    }
  end

  def fail(%__MODULE__{identifier: identifier, attempts: attempts}) do
    %__MODULE__{
      identifier: identifier,
      attempts: attempts + 1,
      last: DateTime.utc_now()
    }
  end
end
