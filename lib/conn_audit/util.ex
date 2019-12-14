defmodule ConnAudit.Util do
  def resolver(%Plug.Conn{remote_ip: {oct1, oct2, oct3, oct4}}) do
    Integer.to_string(oct1) <>
      "." <>
      Integer.to_string(oct2) <> "." <> Integer.to_string(oct3) <> "." <> Integer.to_string(oct4)
  end
end
