define [
  'jquery'
  'compiled/calendar/CommonEvent'
  'compiled/calendar/CommonEvent.Assignment',
  'compiled/calendar/CommonEvent.AssignmentOverride'
  'compiled/calendar/CommonEvent.CalendarEvent'
  'compiled/str/splitAssetString'
], ($, CommonEvent, Assignment, AssignmentOverride, CalendarEvent, splitAssetString) ->

  (data, contexts) ->
    if data == null
      obj = new CommonEvent()
      obj.allPossibleContexts = contexts
      return obj

    actualContextCode = data.context_code
    contextCode = data.effective_context_code || actualContextCode

    type = if data.assignment_overrides
      'assignment_override'
    else if  data.assignment || data.assignment_group_id
      'assignment'
    else
      'calendar_event'

    data = if data.assignment_overrides
      {assignment: data.assignment, assignment_override: data.assignment_overrides[0]}
    else
      data.assignment || data.calendar_event || data
    return null if data.hidden # e.g. parent event of section-level events
    actualContextCode ?= data.context_code
    contextCode ?= data.effective_context_code || data.context_code

    contextInfo = null
    for context in contexts
      if context.asset_string == contextCode
        contextInfo = context
        break

    # If we can't find the context, then we're not sure
    # how to handle or display this, so we ditch it.
    if contextInfo == null
      return null

    parts = splitAssetString(actualContextCode) if actualContextCode isnt contextCode
    actualContextInfo = if parts and items = contextInfo[parts[0]]
      (item for item in items when item.id is parts[1])[0]

    if type == 'assignment'
      obj = new Assignment(data, contextInfo)
    else if type == 'assignment_override'
      obj = new AssignmentOverride(data, contextInfo)
    else
      obj = new CalendarEvent(data, contextInfo, actualContextInfo)

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

    # Only the description can be edited on scheduler events,
    # but that can always be changed whether locked or not
    if obj.object.appointment_group_id && contextInfo.can_create_calendar_events
      obj.can_edit = true

    # frozen assignments can't be deleted
    if obj.assignment?.frozen
      obj.can_delete = false

    obj
