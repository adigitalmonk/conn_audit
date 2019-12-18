defmodule ConnAudit.Util.Test do
  use ExUnit.Case
  alias ConnAudit.Util
  alias Plug.Conn

  doctest Util

  test "resolves a Plug.Conn into a string" do
    resolved = Util.resolver(%Conn{remote_ip: {127, 0, 0, 1}})
    assert resolved == "127.0.0.1"
  end
end
