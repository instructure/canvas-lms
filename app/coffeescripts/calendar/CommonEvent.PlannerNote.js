/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!calendar'
import fcUtil from '../util/fcUtil'
import CommonEvent from '../calendar/CommonEvent'
import {extend} from '../legacyCoffeesScriptHelpers'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_misc_helpers'

const deleteConfirmation = I18n.t('Are you sure you want to delete this To Do item?')
const plannerNotesAPI = '/api/v1/planner_notes'

extend(PlannerNote, CommonEvent)

export default function PlannerNote(data, contextInfo, actualContextInfo) {
  PlannerNote.__super__.constructor.call(this, data, contextInfo, actualContextInfo)
  this.eventType = 'planner_note'
  this.deleteConfirmation = deleteConfirmation
  this.deleteURL = encodeURI(`${plannerNotesAPI}/{{ id }}`)
}

Object.assign(PlannerNote.prototype, {
  // beware: copyDateFromObj is called before our constructor
  // because it's call from super's constructor comes here
  // copyDataFromObject makes the incoming planner_note look like a calendar event
  // if we get here via a request for the list of notes (see EventDataSource), some of the
  // fields are already filled in, but if we get here because we just edited a planner_note
  // they are not.
  /* eslint-disable no-param-reassign */
  copyDataFromObject(data) {
    data.type = 'planner_note'
    data.description = data.details
    data.planner_note_id = data.id
    data.start_at = data.todo_date
    data.end_at = null
    data.all_day = false
    data.url = `${window.location.origin}${plannerNotesAPI}/${data.planner_note_id}`
    data.context_code = data.course_id ? `course_${data.course_id}` : `user_${data.user_id}`
    data.all_context_codes = data.context_code

    if (data.calendar_event) data = data.calendar_event
    this.object = this.calendarEvent = data // eslint-disable-line no-multi-assign
    if (data.id) this.id = `planner_note_${data.id}`
    this.title = data.title || 'Untitled'
    this.start = this.parseStartDate()
    this.end = undefined
    this.allDay = data.all_day
    // see originalStart in super's copyDataFromObject
    if (this.end) this.originalEndDate = fcUtil.clone(this.end)
    this.editable = true
    this.lockedTitle = this.object.parent_event_id != null
    this.description = data.description
    this.addClass(`group_${this.contextCode()}`)

    return PlannerNote.__super__.copyDataFromObject.apply(this, arguments)
  },

  endDate() {
    return this.originalEndDate
  },

  parseStartDate() {
    if (this.calendarEvent.start_at) {
      return fcUtil.wrap(this.calendarEvent.start_at)
    }
  },

  displayTimeString() {
    return this.formatTime(this.startDate())
  },

  readableType() {
    return this.readableTypes[this.event_type]
  },

  // called at the end of a drag and drop operation
  saveDates(success, error) {
    return this.save(
      {
        title: this.title,
        details: this.description,
        todo_date: fcUtil.unwrap(this.start).toISOString(),
        id: this.object.id,
        type: 'planner_note'
      },
      success,
      error
    )
  },

  methodAndURLForSave() {
    let method, url
    if (this.isNewEvent()) {
      method = 'POST'
      url = plannerNotesAPI
    } else {
      method = 'PUT'
      url = `${plannerNotesAPI}/${this.object.id}`
    }
    return [method, url]
  }
})
