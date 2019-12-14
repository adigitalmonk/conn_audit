import Config

config :conn_audit, Auditing,
  ttl: 300_000,
  lockout: 5
