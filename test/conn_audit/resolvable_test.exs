defmodule ConnAudit.Resolvable.Test do
  use ExUnit.Case
  doctest ConnAudit.Resolvable

  test "resolves a Plug.Conn into a string" do
    resolved = ConnAudit.Resolvable.resolve(%Plug.Conn{remote_ip: {127, 0, 0, 1}})
    assert resolved == "127.0.0.1"
  end
end
