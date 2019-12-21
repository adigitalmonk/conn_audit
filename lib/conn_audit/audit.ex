defmodule ConnAudit.Audit do
  @moduledoc false
  defstruct [:token, :attempts, :last]
end
