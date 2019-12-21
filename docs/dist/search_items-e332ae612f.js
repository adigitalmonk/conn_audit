searchNodes=[{"ref":"ConnAudit.html","title":"ConnAudit","type":"module","doc":"This application provides a simple implementation for login brute force protection. The two components for this are the Verification Plug macro and the Auditing API. You can check out the sections below for more information on each component. This application isn&#39;t meant to be a replacement for a real solution and you&#39;d assuredly be better suited using something production-ready. The way the system works is to place a Plug built using the ConnAudit macro in front of your login page. The macro accepts a handler for what to do if the &quot;verification&quot; fails, otherwise it will just pass the Plug.Conn through to the next plug. Verification Plug The verification plug macro will create a plug Plug for you that will check the result of an audit. If the audit passes, it will forward the conn on. If it fails, it will pass the conn into the function that&#39;s passed in. defmodule AuditTest.Plug.Verify do use ConnAudit import Phoenix.Controller, only: [redirect: 2] def on_reject(conn) do conn |&gt; redirect(to: &quot;/403&quot;) |&gt; halt() end end The use ConnAudit macro requires your plug to implement the on_reject function. This function takes a Plug.Conn and returns a Plug.Conn. This allows you to define how yo want to handle a failed audit. Then just add this Plug into your pipeline or attach it whatever routes you want auditing on. This Plug will create a new GenServer for every unique token passed to the Audit API. I&#39;d recommend limiting the number of routes you apply this to. pipeline :audited do plug AuditTest.Plug.Verify end scope &quot;/login&quot;, AuditTestingWeb do pipe_through [:browser, :audited] get &quot;/&quot;, LoginController, :index end You&#39;d be better off relying on sessions to isolate the majority of your pages and having this Plug only on your actual login page. That said, it can be used for any kind of auditing purposes to block access to specific pages, nothing says it has to be used for login controls. The resolution of the Plug.Conn is implemented through a Protocol. You are welcome to re-implement the existing protocol how you deem fit. You could alternatively write an entirely new one and create your own verification plug. The existing one is as follows. defimpl ConnAudit.Resolvable, for: Plug.Conn do def resolve(%Plug.Conn{remote_ip: {oct1, oct2, oct3, oct4}}) do Integer.to_string(oct1) &lt;&gt; &quot;.&quot; &lt;&gt; Integer.to_string(oct2) &lt;&gt; &quot;.&quot; &lt;&gt; Integer.to_string(oct3) &lt;&gt; &quot;.&quot; &lt;&gt; Integer.to_string(oct4) end end Auditing API There are three functions as part of the auditing API. TODO - Define three functions TODO - How the tokens work + resolution defmodule AuditTestWeb.LoginController do # Plug only on this page instead of in pipeline plug AuditTest.Plug.Verify def create(conn, %{ &quot;login_form&quot; =&gt; %{ &quot;username&quot; =&gt; username, &quot;password&quot; =&gt; password } }) do if Accounts.login(username, password) do ConnAudit.succeed(conn) conn |&gt; put_session(:authenticated, username) |&gt; redirect(to: &quot;/&quot;) else ConnAudit.fail(conn) conn |&gt; put_flash(:error, &quot;Invalid username or password.&quot;) |&gt; redirect(to: &quot;/auth/login&quot;) end end end Logging There are four :telemetry events executed in this application. EventDescriptionAtoms Audit SuccessA successful audit was performed for a token[:conn_audit, :audit, :success] Audit FailureAn unsuccessful audit was performed for a token[:conn_audit, :audit, :failure] Audit LockoutA audit was considered &quot;locked out&quot;[:conn_audit, :audit, :lockout] Audit TimeoutThe configured :ttl has passed and an audit is no longer valid[:conn_audit, :audit, :timeout] All of the events have the same parameters and metadata. Parameters attempts is the number of failed attempts that happened up to that point token is the resolved token for the connection / user Metadata timestamp is a UTC DateTime"},{"ref":"ConnAudit.html#__using__/1","title":"ConnAudit.__using__/1","type":"macro","doc":"This will create the necessary code for a Plug to be used in a Plug pipeline or individual Plug controller. The see ConnAudit module description for more information."},{"ref":"ConnAudit.html#check/1","title":"ConnAudit.check/1","type":"function","doc":"Accepts an identifier and will return the current audit status. The audit status will either be :pass if the identifier accepted or or :lockout if denied. This can accept a binary or a struct that implements the ConnAudit.Resolvable protocol."},{"ref":"ConnAudit.html#fail/1","title":"ConnAudit.fail/1","type":"function","doc":"Accepts an identifier and will mark a failed audit. This can accept a binary or a struct that implements the ConnAudit.Resolvable protocol."},{"ref":"ConnAudit.html#succeed/1","title":"ConnAudit.succeed/1","type":"function","doc":"Accepts an identifier and will mark a successful audit. This can accept a binary or a struct that implements the ConnAudit.Resolvable protocol."},{"ref":"ConnAudit.Plug.html","title":"ConnAudit.Plug","type":"behaviour","doc":""},{"ref":"ConnAudit.Plug.html#c:on_reject/1","title":"ConnAudit.Plug.on_reject/1","type":"callback","doc":""},{"ref":"ConnAudit.Resolvable.html","title":"ConnAudit.Resolvable","type":"protocol","doc":"Defines the protocol used for the resolution of a given struct to the binary/string used for uniquely identifying Audits."},{"ref":"ConnAudit.Resolvable.html#resolve/1","title":"ConnAudit.Resolvable.resolve/1","type":"function","doc":"For a given struct, resolve the given struct into a binary Examples iex&gt; ConnAudit.Resolvable.resolve(%Plug.Conn{remote_ip: { 127, 0, 0, 1 }}) &quot;127.0.0.1&quot;"},{"ref":"ConnAudit.Resolvable.html#t:t/0","title":"ConnAudit.Resolvable.t/0","type":"type","doc":""},{"ref":"Logging.html","title":"Logging","type":"module","doc":""},{"ref":"Logging.html#attach_loggers/0","title":"Logging.attach_loggers/0","type":"function","doc":""},{"ref":"Logging.html#handle_event/4","title":"Logging.handle_event/4","type":"function","doc":""},{"ref":"readme.html","title":"ConnAudit","type":"extras","doc":"ConnAudit This application provides a simple implementation for login brute force protection. The two components for this are the Verification Plug macro and the Auditing API. You can check out the sections below for more information on each component. This application isn&#39;t meant to be a replacement for a professional solution and you&#39;d assuredly be better suited using something tried, true, and production ready. I wrote this originally for a small personal project as a form of basic security and had fun doing it. I decided to rewrite it into it&#39;s own module as a way to get more experience in Elixir; writing a DynamicSupervisor, macro, unit tests, module docs, and whatever else is required. The way the system works is to place a Plug built using the ConnAudit macro in front of your login page. The macro accepts a handler for what to do if the &quot;verification&quot; fails, otherwise it will just pass the Plug.Conn through to the next plug. The module ConnAudit also exposes three functions: fail/1 succeed/1 check/1 For more information, refer to the module docs for ConnAudit. Behind the scenes, for every unique verification token that is passed into the system, a dynamic GenServer will spin up named by the unique verification token. The GenServer will keep track of the number of times the fail/1 function has been called. A call to succeed/1 will cause the GenServer to terminate, resetting the audit process. The configured :ttl (time to live) will determine how long an &quot;audit&quot; stays open. After the given amount of time has passed, the audit is resolved and the GenServer tracking the state terminates."},{"ref":"readme.html#installation","title":"ConnAudit - Installation","type":"extras","doc":"You can install this by adding it via Git. def deps do [ {:conn_audit, github: &quot;adigitalmonk/conn_audit&quot;, branch: &quot;master&quot;} ] end You&#39;ll also need to add :conn_audit to your extra applications extra_applications: [:logger, :runtime_tools, :conn_audit]"},{"ref":"readme.html#configuration","title":"ConnAudit - Configuration","type":"extras","doc":"There are two settings for the application. OptionPurpose :ttlThe amount of time (in milliseconds) to maintain an audit. :lockoutThe number of failures before an audit fails. Example for your config.exs. config :conn_audit, Auditing, ttl: 300000, lockout: 5"},{"ref":"readme.html#usage","title":"ConnAudit - Usage","type":"extras","doc":"For usage information and examples, please refer to the ConnAudit module docs. TODO Improve this document Revise @moduledocs and function @docs Add tests Remove telemetry placeholders intended for testing Remove config.exs from local testing"}]