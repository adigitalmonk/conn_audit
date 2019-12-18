defmodule ConnAudit.Util do
  @moduledoc """
  This module provides utility functions that support the ConnAudit module.
  """

  @doc """
  This function accepts a Plug.Conn and converts it a unique binary identifier.
  This is handled by grabbing the remote IP and converting it into a string.

  ## Examples
  iex> ConnAudit.Util.resolver(%Plug.Conn{ remote_ip: { 1, 1, 1, 1 } })
  "1.1.1.1"

  iex> ConnAudit.Util.resolver(%Plug.Conn{ remote_ip: { 10, 10, 2, 20 } })
  "10.10.2.20"
  """
  def resolver(%Plug.Conn{remote_ip: {oct1, oct2, oct3, oct4}}) do
    Integer.to_string(oct1) <>
      "." <>
      Integer.to_string(oct2) <> "." <> Integer.to_string(oct3) <> "." <> Integer.to_string(oct4)
  end
end
