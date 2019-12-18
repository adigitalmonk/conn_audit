defmodule ConnAudit do
  @moduledoc """
  This application provides a simple implementation for login brute force protection.

  The two components for this are the Verification Plug macro and the Auditing API.
  You can check out the sections below for more information on each component.

  This application isn't meant to be a replacement for a _real_ solution and you'd assuredly be better suited using something production-ready.

  The way the system works is to place a `Plug` built using the `ConnAudit` macro in front of your login page.
  The macro accepts a handler for what to do if the "verification" fails, otherwise it will just pass the `Plug.Conn` through to the next plug.


  #### Verification Plug
  The verification plug macro will create a plug `Plug` for you that will check the result of an audit.

  If the audit passes, it will forward the `conn` on.
  If it fails, it will pass the `conn` into the function that's passed in.

  ```elixir
  defmodule AuditTest.Plug.Verify do
    use ConnAudit, on_reject: &handler/1
    import Phoenix.Controller, only: [redirect: 2]

    def handler(conn) do
      conn
      |> redirect(to: "/403")
      |> halt()
    end
  end
  ```

  When you `use ConnAudit`, there are two options that can be passed in.

  The first option, `:on_reject`, is the function that is used to handle the `conn` when an audit false.

  The (optional) second option, `:resolver`, is used to convert a `conn` into a uniquely identifiable string for auditing purposes.
  By default, this resolution is performed by taking the `host_ip` from the connection and converting it into a string.
  E.g., `{127, 0, 0, 1}` -> `"127.0.0.1"`
  If you choose to override this, you can do whatever you want but the token returned by the resolver **must** be a `binary`.

  Then just add this `Plug` into your pipeline or attach it whatever routes you want auditing on.
  This `Plug` will create a new `GenServer` for every unique token passed to the Audit API.
  I'd recommend limiting the number of routes you apply this to.

  ```elixir
    pipeline :audited do
      plug AuditTest.Plug.Verify
    end

    scope "/login", AuditTestingWeb do
      pipe_through [:browser, :audited]
      get "/", LoginController, :index
    end
  ```

  You'd be better off relying on sessions to isolate the majority of your pages and having this `Plug` only on your actual login page.
  That said, it can be used for any kind of auditing purposes to block access to specific pages, nothing says it has to be used for login controls.

  #### Auditing API

  There are three functions as part of the auditing API.

  **TODO - Define three functions**
  **TODO - How the tokens work + resolution**

  ```elixir
  defmodule AuditTestWeb.LoginController do

    # Plug only on this page instead of in pipeline
    plug AuditTest.Plug.Verify

    def create(conn, %{
          "login_form" => %{
            "username" => username,
            "password" => password
          }
        }) do
      if Accounts.login(username, password) do
        ConnAudit.succeed(conn)

        conn
        |> put_session(:authenticated, username)
        |> redirect(to: "/")
      else
        ConnAudit.fail(conn)

        conn
        |> put_flash(:error, "Invalid username or password.")
        |> redirect(to: "/auth/login")
      end
    end
  end
  ```

  ## Logging

  There are four `:telemetry` events executed in this application.

  | Event | Description | Atoms |
  | :---: | :---: | :---: |
  | Audit Success | A successful audit was performed for a token | `[:conn_audit, :audit, :success]` |
  | Audit Failure | An unsuccessful audit was performed for a token | `[:conn_audit, :audit, :failure]` |
  | Audit Lockout | A audit was considered "locked out" | `[:conn_audit, :audit, :lockout]` |
  | Audit Timeout | The configured `:ttl` has passed and an audit is no longer valid | `[:conn_audit, :audit, :timeout]` |

  All of the events have the same parameters and metadata.

  ### Parameters

  - `attempts` is the number of failed attempts that happened up to that point
  - `token` is the resolved token for the connection / user

  ### Metadata

  - `timestamp` is a UTC `DateTime`

  """

  alias ConnAudit.Util
  alias ConnAudit.Auditor

  @doc """
  Accepts an identifier and will mark a failed audit.

  This can accept either `Plug.Conn` or a pre-resolved binary.
  If providing a `Plug.Conn`, it will resolve it using the default resolver `ConnAudit.Util.resolver/1`
  """
  def fail(%Plug.Conn{} = conn) do
    Util.resolver(conn)
    |> fail()
  end

  def fail(token) when is_binary(token) do
    Auditor.fail(token)
  end

@doc """
  Accepts an identifier and will mark a successful audit.

  This can accept either `Plug.Conn` or a pre-resolved binary.
  If providing a `Plug.Conn`, it will resolve it using the default resolver `ConnAudit.Util.resolver/1`
  """
  def succeed(%Plug.Conn{} = conn) do
    Util.resolver(conn)
    |> succeed()
  end

  def succeed(token) when is_binary(token) do
    Auditor.succeed(token)
  end

  @doc """
  Accepts an identifier and will return the current audit status.
  The audit status will either be :pass if the identifier accepted or or :lockout if denied.

  This can accept either `Plug.Conn` or a pre-resolved binary.
  If providing a `Plug.Conn`, it will resolve it using the default resolver `ConnAudit.Util.resolver/1`
  """
  def check(%Plug.Conn{} = conn) do
    Util.resolver(conn)
    |> check()
  end

  def check(token) when is_binary(token) do
    Auditor.check(token)
  end

  @doc """
  This will create the necessary code for a `Plug` to be used in a `Plug` pipeline or individual `Plug` controller.

  The see `ConnAudit` module description for more information.
  """
  defmacro __using__(opts) do
    handler = Keyword.get(opts, :on_reject)

    resolver =
      case Keyword.get(opts, :resolver) do
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
