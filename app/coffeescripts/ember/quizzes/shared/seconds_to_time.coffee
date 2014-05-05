define [], () ->
   # Format a duration given in seconds into a stopwatch-style timer, e.g:
   #
   #   1 second      => 00:01
   #   30 seconds    => 00:30
   #   84 seconds    => 01:24
   #   7230 seconds  => 02:00:30
   #   7530 seconds  => 02:05:30

  (seconds) ->
    floor = Math.floor
    pad = (duration) ->
      ('00' + duration).slice(-2)

    if seconds > 3600
      hh = floor (seconds / 3600)
      mm = floor ((seconds - hh*3600) / 60)
      ss = seconds % 60
      "#{pad hh}:#{pad mm}:#{pad ss}"
    else
      "#{pad floor seconds / 60}:#{pad floor seconds % 60}"
