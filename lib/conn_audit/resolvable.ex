defprotocol ConnAudit.Resolvable do
  @moduledoc """
  Defines the protocol used for the resolution of a given struct to the binary/string used for uniquely identifying Audits.
  """

  @doc """
  For a given struct, resolve the given struct into a binary

  ## Examples
  iex> ConnAudit.Resolvable.resolve(%Plug.Conn{remote_ip: { 127, 0, 0, 1 }})
  "127.0.0.1"
  """
  @spec resolve(struct) :: binary
  def resolve(struct)
end

defimpl ConnAudit.Resolvable, for: Plug.Conn do
  @spec resolve(Plug.Conn.t()) :: binary
  def resolve(%Plug.Conn{remote_ip: remote_ip}) do
    remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
