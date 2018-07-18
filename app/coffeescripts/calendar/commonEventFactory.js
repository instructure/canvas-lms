/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import CommonEvent from '../calendar/CommonEvent'
import Assignment from '../calendar/CommonEvent.Assignment'
import AssignmentOverride from '../calendar/CommonEvent.AssignmentOverride'
import CalendarEvent from '../calendar/CommonEvent.CalendarEvent'
import PlannerNote from '../calendar/CommonEvent.PlannerNote'
import splitAssetString from '../str/splitAssetString'

export default function commonEventFactory(data, contexts) {
  let items, obj, parts
  if (data == null) {
    obj = new CommonEvent()
    obj.allPossibleContexts = contexts
    obj.can_change_context = true
    return obj
  }

  let actualContextCode = data.context_code
  let contextCode = data.effective_context_code || actualContextCode

  const type = data.assignment_overrides ? 'assignment_override' :
    data.assignment || data.assignment_group_id ? 'assignment' :
    data.type === 'planner_note' ? 'planner_note' :
    data.plannable ? 'todo_item' :
    'calendar_event'

  data = data.assignment_overrides
    ? {assignment: data.assignment, assignment_override: data.assignment_overrides[0]}
    : data.assignment || data.calendar_event || data
  if (data.hidden) {
    return null
  } // e.g. parent event of section-level events
  if (actualContextCode == null) {
    actualContextCode = data.context_code
  }
  if (contextCode == null) {
    contextCode = data.effective_context_code || data.context_code
  }

  let contextInfo = contexts.find(context => context.asset_string === contextCode)

  // match one of a multi-context event
  if (contextInfo == null && contextCode && contextCode.indexOf(',') >= 0) {
    const contextCodes = contextCode.split(',')
    contextInfo = contexts.find(context => contextCodes.includes(context.asset_string))
  }

  // If we can't find the context, then we're not sure
  // how to handle or display this, so we ditch it.
  if (contextInfo == null) return null

  if (actualContextCode !== contextCode) {
    parts = splitAssetString(actualContextCode)
  }
  const actualContextInfo =
    parts && (items = contextInfo[parts[0]]) && items.filter(item => item.id === parts[1])[0]

  if (type === 'assignment') {
    obj = new Assignment(data, contextInfo)
  } else if (type === 'assignment_override') {
    obj = new AssignmentOverride(data, contextInfo)
  } else if (type === 'planner_note') {
    obj = new PlannerNote(data, contextInfo, actualContextInfo)
  } else {
    obj = new CalendarEvent(data, contextInfo, actualContextInfo)
  }

  // TODO: Improve permissions handling
  // The API is not currently telling us what permissions a user
  // has on each object it returns. So, we're going to guess by
  // the following assumptions:
  obj.can_edit = false
  obj.can_delete = false
  obj.can_change_context = false

  if (obj.object.appointment_group_id) {
    // for events linked to appointment groups, use appointment group permissions
    // because e.g. students can create group calendar events but cannot edit group AGs
    if (obj.object.can_manage_appointment_group) {
      obj.can_edit = true
      obj.can_delete = true
    }
  } else {
    // If the user can create an event in a context, they can also edit/delete
    // any events in that context.
    if (contextInfo.can_create_calendar_events) {
      obj.can_edit = true
      obj.can_delete = true
    }
    // If the event has a state "locked" - in which case, it can't be
    // edited (but it could be deleted)
    if (obj.object.workflow_state === 'locked') {
      obj.can_edit = false
    }
  }

  // frozen assignments can't be deleted
  if (obj.assignment && obj.assignment.frozen) {
    obj.can_delete = false
  }

  // events can be moved to a different calendar in limited circumstances
  if (type === 'calendar_event') {
    if (
      !obj.object.appointment_group_id &&
      !obj.object.parent_event_id &&
      !obj.object.child_events_count &&
      !obj.object.effective_context_code
    ) {
      obj.can_change_context = true
    }
  }

  if (type === 'planner_note') {
    // planner_notes can only be created by the user for herself,
    // so she can always edit them
    obj.can_change_context = true // TODO: will change to false when note is linked to an asset
    obj.can_edit = true
    obj.can_delete = true
  }

  // TODO make todo items editable, but for now prevent brokenness when the user tries
  if (type === 'todo_item') {
    obj.can_edit = false
    obj.can_delete = false
  }

  // disable fullcalendar.js dragging unless the user has permissions
  if (!obj.can_edit) obj.editable = false

  return obj
}
