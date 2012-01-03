define 'compiled/calendar/commonEventFactory', [
  'compiled/calendar/CommonEvent'
  'compiled/calendar/CommonEvent.Assignment',
  'compiled/calendar/CommonEvent.CalendarEvent'
], (CommonEvent, Assignment, CalendarEvent) ->

  (data, contexts) ->
    if data == null
      obj = new CommonEvent()
      obj.allPossibleContexts = contexts
      return obj

    context_code = data.context_code || data.assignment?.context_code || data.calendar_event?.context_code

    type = null
    if data.assignment || data.assignment_group_id
      type = 'assignment'
    else
      type = 'calendar_event'

    data = data.assignment || data.calendar_event || data

    contextInfo = null
    for context in contexts
      if context.asset_string == context_code
        contextInfo = context
        break

    console.log("#{type} #{data.id} #{contextInfo}")

    # If we can't find the context, then we're not sure
    # how to handle or display this, so we ditch it.
    if contextInfo == null
      return null

    if type == 'assignment'
      obj = new Assignment(data, contextInfo)
    else
      obj = new CalendarEvent(data, contextInfo)

    # TODO: Improve permissions handling
    # The API is not currently telling us what permissions a user
    # has on each object it returns. So, we're going to guess by
    # the following assumptions:
    obj.can_edit = false
    obj.can_delete = false
    # If the user can create an event in a context, they can also edit/delete
    # any events in that context.
    if contextInfo.can_create_calendar_events
      obj.can_edit = true
      obj.can_delete = true
    # If the event has a state "locked" - in which case, it can't be
    # edited (but it could be deleted)
    if obj.object.workflow_state == 'locked'
      obj.can_edit = false
    # Any scheduler events can't be edited currently (but can be deleted)
    if obj.object.appointment_group_id
      obj.can_edit = false


    obj