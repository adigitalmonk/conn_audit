defmodule ConnAudit.Limiting.State do
  @moduledoc false
  defstruct [:identifier, :accessed, :last]

  def new(identifier) do
    %__MODULE__{
      identifier: identifier,
      accessed: 0,
      last: nil
    }
  end

  def accessed(%__MODULE__{accessed: accessed} = state) do
    %__MODULE__{
      state |
      last: DateTime.utc_now(),
      accessed: accessed + 1
    }
  end

  def failed_attempt(%__MODULE__{accessed: accessed} = state) do
    %__MODULE__{state | accessed: accessed + 1}
  end
end
