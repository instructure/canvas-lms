/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import fcUtil from '../util/fcUtil'

// We want to filter events received from the datasource. It seems like you should be able
// to do this at render time as well, and return "false" in eventRender, but on the agenda
// view that still assumes that the item is taking up space even though it's not displayed.
// De-dupe, and remove any actual scheduled events (since we don't want to
// display that among the placeholders.)

export default function calendarEventFilter(viewingGroup, events, schedulerState = {}) {
  const eventIds = {}
  if (!(events.length > 0)) return events
  for (let idx = events.length; idx--; ) {
    const event = events[idx]
    let keep = true
    let gray = schedulerState.inFindAppointmentMode
    // De-dupe
    if (eventIds[event.id]) {
      keep = false
    } else if (event.isAppointmentGroupEvent()) {
      if (!viewingGroup || ENV.CALENDAR.BETTER_SCHEDULER) {
        // Handle normal calendar view, not scheduler view
        if (!event.calendarEvent.reserve_url) {
          // If there is not a reserve_url set, then it is an
          // actual, scheduled event and not just a placeholder.
          keep = true
        } else if (!event.calendarEvent.reserved && event.can_edit) {
          // manageable appointment slot not reserved by me
          if (schedulerState.hasOwnProperty('inFindAppointmentMode')) {
            // new scheduler is enabled: show unconditionally; gray if no one is signed up
            // or if we are in find-appointment mode looking to sign up somewhere else
            keep = true
            gray =
              event.calendarEvent.child_events_count === 0 || schedulerState.inFindAppointmentMode
          } else {
            // new scheduler is not enabled: show only if someone is signed up
            keep = event.calendarEvent.child_events_count > 0
          }
        } else {
          // appointment slot
          if (
            schedulerState.inFindAppointmentMode &&
            event.isOnCalendar(schedulerState.selectedCourse.asset_string)
          ) {
            // show it (non-grayed) if it is reservable; filter it out otherwise
            if (
              event.calendarEvent.reserved ||
              event.calendarEvent.available_slots === 0 ||
              event.endDate() < fcUtil.now()
            ) {
              keep = false
            } else {
              gray = false
            }
          } else {
            // normal calendar mode: hide reservable slots
            keep = false
          }
        }
      } else if (
        viewingGroup.id === (event.calendarEvent && event.calendarEvent.appointment_group_id)
      ) {
        // If this is an actual event for an appointment, don't show it
        keep = !!event.calendarEvent.reserve_url
      } else {
        // If this is an appointment event for a different appointment group, and it's full, show it
        keep = !event.calendarEvent.reserve_url
      }
    }

    // needed for undated assignement edit
    if (!event.start) keep = false

    event[gray ? 'addClass' : 'removeClass']('grayed')

    if (!keep) events.splice(idx, 1)

    eventIds[event.id] = true
  }

  return events
}
