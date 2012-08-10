define ['jquery'], ($) ->

  # like $.when, except it transforms rejects into resolves. useful when you
  # don't care if some items succeed or not, but you want to wait until
  # everything completes before you resolve (or reject) ... the default $.when
  # behavior is to reject as soon as the first dependency rejects.

  $.whenAll = (dfds...) ->
    dfds = for d in dfds
      do ->
        dfd = $.Deferred()
        $.when(d).always (args...) ->
          dfd.resolve args...
        dfd.promise()
    $.when dfds...
  $