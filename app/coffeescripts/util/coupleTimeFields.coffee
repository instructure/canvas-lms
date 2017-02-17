define ['jquery'], ($) ->
  ($start, $end, $date) ->
    # construct blur callback that couples them in order so that $start can
    # never be less than $end
    blur = ($blurred) ->
      if $date and $blurred is $date
        date = $date.data('unfudged-date')
        if date
          $start.data('instance')?.setDate(date)
          $end.data('instance')?.setDate(date)
        return

      # these will be null if invalid or blank, and date values otherwise.
      start = $start.data('unfudged-date')
      end = $end.data('unfudged-date')

      realStart = $start.data('date')
      realEnd = $end.data('date')

      if start and end
        # we only care about comparing the time of day, not the date portion
        # (since they'll both be interpreted relative to some other date field
        # later)
        start = start.clone()
        start.setFullYear(end.getFullYear())
        start.setMonth(end.getMonth())
        start.setDate(end.getDate())

        if realEnd < realStart
          # both present and valid, but violate expected ordering, set the one
          # not just changed equal to the one just changed
          if $blurred is $end
            $start.data('instance').setTime(end)
          else
            $end.data('instance').setTime(start)

    # use that blur function for both fields
    $start.blur -> blur($start)
    $end.blur -> blur($end)
    if $date
      $date.on('blur change', -> blur($date))
      blur($date)

    # trigger initial coupling check
    blur($end)
