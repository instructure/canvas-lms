define ['jquery'], ($) ->
  ($start, $end) ->
    # construct blur callback that couples them in order so that $start can
    # never be less than $end
    blur = ($blurred) ->
      # these will be null if invalid or blank, and date values otherwise.
      start = $start.data('unfudged-date')
      end = $end.data('unfudged-date')

      if start and end
        # we only care about comparing the time of day, not the date portion
        # (since they'll both be interpreted relative to some other date field
        # later)
        start = start.clone()
        start.setFullYear(end.getFullYear())
        start.setMonth(end.getMonth())
        start.setDate(end.getDate())
        if end < start
          # both present and valid, but violate expected ordering, set the one
          # not just changed equal to the one just changed
          if $blurred is $end
            $start.data('instance').setTime(end)
          else
            $end.data('instance').setTime(start)

    # use that blur function for both fields
    $start.blur -> blur($start)
    $end.blur -> blur($end)

    # trigger initial coupling check
    blur($end)
