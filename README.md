# ConnAudit

This application provides a simple implementation for login brute force protection.

The two components for this are the Verification Plug macro and the Auditing API.
You can check out the sections below for more information on each component.

This application isn't meant to be a replacement for a professional solution and you'd assuredly be better suited using something tried, true, and production ready.
I wrote this originally for a small personal project as a form of basic security and had fun doing it.

I decided to rewrite it into it's own module as a way to get more experience in Elixir; writing a `DynamicSupervisor`, macro, unit tests, module docs, and whatever else is required.

The way the system works is to place a Plug built using the `ConnAudit` macro in front of your login page.
The macro accepts a handler for what to do if the "verification" fails, otherwise it will just pass the `Plug.Conn` through to the next plug.

The module `ConnAudit` also exposes three functions:

- `fail/1`
- `succeed/1`
- `check/1`

For more information, refer to the module docs for `ConnAudit`.

Behind the scenes, for every unique verification token that is passed into the system, a dynamic `GenServer` will spin up named by the unique verification token.

The `GenServer` will keep track of the number of times the `fail/1` function has been called.
A call to `succeed/1` will cause the `GenServer` to terminate, resetting the audit process.
The configured `:ttl` (time to live) will determine how long an "audit" stays open.
After the given amount of time has passed, the audit is resolved and the `GenServer` tracking the state terminates.

## Installation

** TODO: Write this better **

You can install this by adding it via Git.

```elixir
def deps do
  [
    {:conn_audit, github: "adigitalmonk/conn_audit", branch: "master"}
  ]
end
```

## Configuration

There are two settings for the application.

| Option | Purpose |
| :----- | :-----: |
| `:ttl` | The amount of time (in milliseconds) to maintain an audit. |
| `:lockout` | The number of failures before an audit fails. |

Example for your `config.exs`.

```elixir
config :conn_audit, Auditing,
  ttl: 300000,
  lockout: 5
```

## Usage

For usage information and examples, please refer to the `ConnAudit` module docs.

# TODO

- Improve this document
- Simplify `resolver` configuration for Auditing API
- Write moduledocs
- Remove telemetry placeholders intended for testing
- Add tests
- Remove `config.exs` from local testing
