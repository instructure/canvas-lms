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
        if !viewingGroup || ENV.CALENDAR.BETTER_SCHEDULER
          # Handle normal calendar view, not scheduler view
          if !event.calendarEvent.reserve_url
            # If there is not a reserve_url set, then it is an
            # actual, scheduled event and not just a placeholder.
            keep = true
          else if !event.calendarEvent.reserved && event.can_edit
            # manageable appointment slot not reserved by me
            if schedulerState.hasOwnProperty 'inFindAppointmentMode'
              # new scheduler is enabled: show unconditionally; gray if no one is signed up
              # or if we are in find-appointment mode looking to sign up somewhere else
              keep = true
              gray = event.calendarEvent.child_events_count == 0 || schedulerState.inFindAppointmentMode
            else
              # new scheduler is not enabled: show only if someone is signed up
              keep = event.calendarEvent.child_events_count > 0
          else
            # appointment slot
            if schedulerState.inFindAppointmentMode && event.isOnCalendar(schedulerState.selectedCourse.asset_string)
              # show it (non-grayed) if it is reservable; filter it out otherwise
              if event.calendarEvent.reserved || event.calendarEvent.available_slots == 0
                keep = false
              else
                gray = false
            else
              # normal calendar mode: hide reservable slots
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
