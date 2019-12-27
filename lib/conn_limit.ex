defmodule ConnAudit.Limiter do
  # @moduledoc """
  #   TBD
  # """

  # alias ConnAudit.Limiting.Limiter
  # import ConnAudit.Resolvable

  # @doc """
  # Accepts an identifier and will mark a failed audit.

  # This can accept a binary or a struct that implements the `ConnAudit.Resolvable` protocol.
  # """
  # def fail(token) when is_binary(token) do
  #   Auditor.fail(token)
  # end

  # def fail(resolvable) do
  #   resolve(resolvable)
  #   |> fail()
  # end

  # @doc """
  # Accepts an identifier and will mark a successful audit.

  # This can accept a binary or a struct that implements the `ConnAudit.Resolvable` protocol.
  # """
  # def succeed(token) when is_binary(token) do
  #   Auditor.succeed(token)
  # end

  # def succeed(resolvable) do
  #   resolve(resolvable)
  #   |> succeed()
  # end

  # @doc """
  # Accepts an identifier and will return the current audit status.
  # The audit status will either be :pass if the identifier accepted or or :lockout if denied.

  # This can accept a binary or a struct that implements the `ConnAudit.Resolvable` protocol.
  # """
  # def check(token) when is_binary(token) do
  #   Auditor.check(token)
  # end

  # def check(resolvable) do
  #   resolve(resolvable)
  #   |> check()
  # end

  # @doc """
  # This will create the necessary code for a `Plug` to be used in a `Plug` pipeline or individual `Plug` controller.

  # The see `ConnAudit` module description for more information.
  # """
  # defmacro __using__(_opts) do
  #   quote do
  #     import Plug.Conn
  #     import ConnAudit.Resolvable
  #     @behaviour ConnAudit.Plug

  #     def init(opts), do: opts

  #     def call(conn, _opts) do
  #       token = resolve(conn)

  #       case ConnAudit.check(token) do
  #         :pass ->
  #           conn

  #         _ ->
  #           on_reject(conn)
  #       end
  #     end
  #   end
  # end
end
