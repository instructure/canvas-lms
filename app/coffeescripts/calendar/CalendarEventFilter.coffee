define [], () ->
  # We want to filter events received from the datasource. It seems like you should be able
  # to do this at render time as well, and return "false" in eventRender, but on the agenda
  # view that still assumes that the item is taking up space even though it's not displayed.
  (viewingGroup, events, schedulerState = {}) ->
    # De-dupe, and remove any actual scheduled events (since we don't want to
    # display that among the placeholders.)
    eventIds = {}
    return events unless events.length > 0
    for idx in [events.length - 1..0] # CS doesn't have a way to iterate a list in reverse ?!
      event = events[idx]
      keep = true
      gray = schedulerState.inFindAppointmentMode
      # De-dupe
      if eventIds[event.id]
        keep = false
      else if event.isAppointmentGroupEvent()
        if !viewingGroup
          # Handle normal calendar view, not scheduler view
          if !event.calendarEvent.reserve_url
            # If there is not a reserve_url set, then it is an
            # actual, scheduled event and not just a placeholder.
            keep = true
          else if !event.calendarEvent.reserved && event.can_edit
            # If this *is* a placeholder, and it has child events, and it's not reserved by me,
            # that means people have signed up for it, so we want to display it if I am able to
            #  manage it (as a teacher or TA might)
            if schedulerState.hasOwnProperty 'inFindAppointmentMode'
              keep = true
              gray = event.calendarEvent.child_events_count == 0 || schedulerState.inFindAppointmentMode
            else
              keep = event.calendarEvent.child_events_count > 0
          else
            if schedulerState.inFindAppointmentMode && event.isOnCalendar(schedulerState.selectedCourse.asset_string)
              gray = false
            else
              keep = false
        else
          if viewingGroup.id == event.calendarEvent?.appointment_group_id
            # If this is an actual event for an appointment, don't show it
            keep = !!event.calendarEvent.reserve_url
          else
            # If this is an appointment event for a different appointment group, and it's full, show it
            keep = !event.calendarEvent.reserve_url

      # needed for undated assignement edit
      keep = false if !event.start

      if gray
        event.addClass('grayed')
      else
        event.removeClass('grayed')

      events.splice(idx, 1) unless keep
      eventIds[event.id] = true

    events
