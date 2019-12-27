defmodule ConnAudit.Plug do
  @callback on_reject(Plug.Conn.t) :: Plug.Conn.t
end
