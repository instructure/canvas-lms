# A console interface you can use for logging that will be mute unless you
# explicitly tell it not to be by setting "debug_js=1" in the query string.
#
# @return {Object}
#   An object that has an API similar to `console` and responds to the methods:
#   "debug", "info", "log", "warn", "error"
define [], ->
  if (''+location.search).match(/[?&]debug_js=1/)
    console
  else
    sink = () ->
    [ 'debug', 'info', 'log', 'warn', 'error' ].reduce (logger, logLevel) ->
      logger[logLevel] = sink
      logger
    , {}
