defmodule ConnAudit.Auditor do
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
    use ConnAudit
    import Phoenix.Controller, only: [redirect: 2]

    def on_reject(conn) do
      conn
      |> redirect(to: "/403")
      |> halt()
    end
  end
  ```

  The `use ConnAudit` macro requires your plug to implement the `on_reject` function.
  This function takes a `Plug.Conn` and returns a `Plug.Conn`.
  This allows you to define how yo want to handle a failed audit.

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

  The resolution of the `Plug.Conn` is implemented through a Protocol.
  You are welcome to re-implement the existing protocol how you deem fit.
  You could alternatively write an entirely new one and create your own verification plug.

  The existing one is as follows.

  ```elixir
  defimpl ConnAudit.Resolvable, for: Plug.Conn do
    def resolve(%Plug.Conn{remote_ip: {oct1, oct2, oct3, oct4}}) do
      Integer.to_string(oct1) <> "." <>
      Integer.to_string(oct2) <> "." <>
      Integer.to_string(oct3) <> "." <>
      Integer.to_string(oct4)
    end
  end
  ```

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

  alias ConnAudit.Auditing.Auditor
  import ConnAudit.Resolvable

  @doc """
  Accepts an identifier and will mark a failed audit.

  This can accept a binary or a struct that implements the `ConnAudit.Resolvable` protocol.
  """
  def fail(token) when is_binary(token) do
    Auditor.fail(token)
  end

  def fail(resolvable) do
    resolve(resolvable)
    |> fail()
  end

  @doc """
  Accepts an identifier and will mark a successful audit.

  This can accept a binary or a struct that implements the `ConnAudit.Resolvable` protocol.
  """
  def succeed(token) when is_binary(token) do
    Auditor.succeed(token)
  end

  def succeed(resolvable) do
    resolve(resolvable)
    |> succeed()
  end

  @doc """
  Accepts an identifier and will return the current audit status.
  The audit status will either be :pass if the identifier accepted or or :lockout if denied.

  This can accept a binary or a struct that implements the `ConnAudit.Resolvable` protocol.
  """
  def check(token) when is_binary(token) do
    Auditor.check(token)
  end

  def check(resolvable) do
    resolve(resolvable)
    |> check()
  end

  @doc """
  This will create the necessary code for a `Plug` to be used in a `Plug` pipeline or individual `Plug` controller.

  The see `ConnAudit` module description for more information.
  """
  defmacro __using__(_opts) do
    quote do
      import Plug.Conn
      import ConnAudit.Resolvable
      @behaviour ConnAudit.Plug

      def init(opts), do: opts

      def call(conn, _opts) do
        token = resolve(conn)

        case ConnAudit.check(token) do
          :pass ->
            conn

          _ ->
            on_reject(conn)
        end
      end
    end
  end
end
