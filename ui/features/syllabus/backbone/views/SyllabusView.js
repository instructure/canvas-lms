/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import $ from 'jquery'
import {reduce, each} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../jst/Syllabus.handlebars'

function assignmentSubType(json) {
  if (/discussion/.test(json.submission_types)) return 'discussion_topic'
  if (/quiz/.test(json.submission_types)) return 'quiz'
  return undefined
}
export default class SyllabusView extends Backbone.View {
  static initClass() {
    this.prototype.template = template
  }

  initialize({can_read, is_valid_user}) {
    this.can_read = can_read
    this.is_valid_user = is_valid_user
    return super.initialize(...arguments)
  }

  // Normalizes the JSON for all of the aggregated event types
  // into something simpler for the template to consume
  //
  // Example output:
  // {
  //    // Array of the date objects
  //    "dates": [ ... ]
  // }
  //
  // Example date object:
  // {
  //   // Date object for the date at midnight (null for undated events)
  //   "date": new Date(),
  //
  //   // Indicates whether the date is in the past
  //   "passed": true,
  //
  //   // Array of event objects that start on this day
  //   "events": [ ... ]
  // }
  //
  // Example event object:
  // {
  //    // Identifier to associate related events
  //    "related_id": "assignment_1",
  //
  //    // Assignment or other type of event
  //    "type": "assignment|event",
  //
  //    // Title of the event
  //    "title": "Event title",
  //
  //    // URL for the user to access details on the assignment/event
  //    "html_url": "http://...",
  //
  //    // Date the event begins (this is the due_at date for assignments)
  //    "start_at": "2012-01-01T23:59:00-07:00",
  //
  //    // Date the event ends (this is the due_at date for assignments)
  //    "end_at": "2012-01-01T23:59:00-07:00",
  //
  //    // Date the event is due (null for non-assignment events)
  //    "due_at": "2012-01-01T23:59:00-07:00",
  //
  //    // Indicates that the start and end times are on the same day
  //    "same_day": true,
  //
  //    // Indicates that the start and end times are the same time
  //    "same_time": true,
  //
  //    // Indicates that this event is the last on the same day
  //    "last": false,
  //
  //    // Override information associated with this event (null for non-overwritten)
  //    "override": {
  //        // Title for the override
  //        "title": "Overridden for James"
  //    }
  //
  //    // The original JSON from the model
  //    "json": { ... }
  // }
  toJSON() {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const html_url_for_assignment = this.can_read
    const html_url_for_event = this.can_read && this.is_valid_user // since the calendar page doesn't support anonymous access yet

    const relatedEvents = {}
    let lastDate = null
    let lastEvent = null
    const dateCollator = function (memo, json) {
      let due_at, end_at, html_url, start_at, todo_at
      let related_id = json.related_id
      if (related_id == null) {
        related_id = json.id
      }
      if (json.type === 'assignment') {
        if (html_url_for_assignment) {
          html_url = json.html_url
        }
      } else if (html_url_for_event) {
        html_url = json.html_url
      }

      const title = json.title
      if (json.start_at) {
        start_at = $.fudgeDateForProfileTimezone(json.start_at)
      }
      if (json.end_at) {
        end_at = $.fudgeDateForProfileTimezone(json.end_at)
      }
      if (json.type === 'assignment') {
        due_at = start_at
      } else if (json.type === 'wiki_page' || json.type === 'discussion_topic') {
        todo_at = $.fudgeDateForProfileTimezone(json.todo_at)
      }

      let override = null
      each(json.assignment_overrides != null ? json.assignment_overrides : [], ov => {
        if (override == null) {
          override = {}
        }
        return (override.title = ov.title)
      })

      let start_date = null
      let orig_start_date = null
      if (start_at) {
        start_date = new Date(start_at.getFullYear(), start_at.getMonth(), start_at.getDate())
        orig_start_date = Date.parse(json.start_at)
      }

      let end_date = null
      if (end_at) {
        end_date = new Date(end_at.getFullYear(), end_at.getMonth(), end_at.getDate())
      }

      if (
        !lastDate ||
        (lastDate.date != null ? lastDate.date.getTime() : undefined) !==
          (start_date != null ? start_date.getTime() : undefined)
      ) {
        lastDate = {
          date: start_date,
          orig_date: orig_start_date,
          passed: start_date && start_date < today,
          events: [],
        }

        memo.push(lastDate)
        lastEvent = null
      } else if (lastEvent) {
        lastEvent.last = false
      }

      lastEvent = {
        related_id,
        type: json.type,
        subtype: assignmentSubType(json),
        title,
        html_url,
        start_at,
        end_at,
        due_at,
        orig_date: orig_start_date,
        todo_at,
        same_day:
          (start_date != null ? start_date.getTime() : undefined) ===
          (end_date != null ? end_date.getTime() : undefined),
        same_time:
          (start_at != null ? start_at.getTime() : undefined) ===
          (end_at != null ? end_at.getTime() : undefined),
        last: true,
        override,
        json,
        workflow_state: json.workflow_state,
      }

      lastDate.events.push(lastEvent)

      lastDate.events.forEach(event => {
        event.eventCount = lastDate.events.length
        event.date = lastDate.date
        event.passed = lastDate.passed
      })

      if (!(related_id in relatedEvents)) {
        relatedEvents[related_id] = []
      }
      relatedEvents[related_id].push(lastEvent)

      return memo
    }

    // Get the dates and events
    const dates = reduce(super.toJSON(...arguments), dateCollator, [])

    // Remove extraneous override information for single events
    let overrides_present = false
    for (const id in relatedEvents) {
      const events = relatedEvents[id]
      if (events.length === 1) {
        events[0].override = null
      } else {
        for (const event of Array.from(events)) {
          // eslint-disable-next-line no-bitwise
          overrides_present |= event.override !== null
        }
      }
    }

    // Return the dates and events in a handlebars friendly way
    return {
      dates,
      overrides_present,
    }
  }
}
SyllabusView.initClass()
