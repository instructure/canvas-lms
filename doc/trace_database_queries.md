# Trace Database Queries

Canvas includes the "active_record_query_trace" gem when running in development mode. This gem
prints a stack trace of every ActiveRecord query the Rails application makes.

The query trace logging is off by default, but can be enabled and configured by setting
environment variables. Note that traces can _only_ be enabled in development mode.

## Environment variable overview

| ENV VAR | Description |
|---------| ----------- |
| AR_QUERY_TRACE | traces are enabled if this variable is set. Traces disabled otherwise. |
| AR_QUERY_TRACE_TYPE | Controls what kind of queries print traces. Valid values are "all", "write", and "read". |
| AR_QUERY_TRACE_LINES | Controls how many lines of the trace are printed. Defaults to 10. |
