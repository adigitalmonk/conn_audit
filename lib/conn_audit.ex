defmodule ConnAudit do
  alias ConnAudit.Util
  alias ConnAudit.Auditor

  def fail(%Plug.Conn{} = conn) do
    Util.resolver(conn)
    |> fail()
  end

  def fail(token) when is_binary(token) do
    Auditor.fail(token)
  end

  def succeed(%Plug.Conn{} = conn) do
    Util.resolver(conn)
    |> succeed()
  end

  def succeed(token) when is_binary(token) do
    Auditor.succeed(token)
  end

  def check(%Plug.Conn{} = conn) do
    Util.resolver(conn)
    |> check()
  end

  def check(token) when is_binary(token) do
    Auditor.check(token)
  end

  @on_reject :on_reject
  @resolver :resolver

  defmacro __using__(opts) do
    handler = Keyword.get(opts, @on_reject)

    resolver =
      case Keyword.get(opts, @resolver) do
        nil -> &ConnAudit.Util.resolver/1
        resolver -> resolver
      end

    quote do
      import Plug.Conn

      def init(opts), do: opts

      def call(conn, _opts) do
        token = unquote(resolver).(conn)

        case ConnAudit.check(token) do
          :pass ->
            conn

          _ ->
            unquote(handler).(conn)
        end
      end
    end
  end
end
