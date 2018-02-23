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

import I18n from 'i18n!calendar'
import $ from 'jquery'
import CommonEvent from '../calendar/CommonEvent'
import fcUtil from '../util/fcUtil'
import {extend} from '../legacyCoffeesScriptHelpers'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_misc_helpers'

const deleteConfirmation = I18n.t(
  'prompts.delete_assignment',
  'Are you sure you want to delete this assignment?'
)

extend(Assignment, CommonEvent)
export default function Assignment(data, contextInfo) {
  Assignment.__super__.constructor.apply(this, arguments)
  this.eventType = 'assignment'
  this.deleteConfirmation = deleteConfirmation
  this.deleteURL = contextInfo.assignment_url
  this.addClass('assignment')
}

Object.assign(Assignment.prototype, {
  copyDataFromObject(data) {
    if (data.assignment) data = data.assignment
    this.object = this.assignment = data
    if (data.id) this.id = `assignment_${data.id}`
    this.title = data.title || data.name || 'Untitled' // due to a discrepancy between the legacy ajax API and the v1 API
    this.lock_explanation = this.object.lock_explanation
    this.addClass(`group_${this.contextCode()}`)
    this.description = data.description
    this.start = this.parseStartDate()
    this.end = null // in case it got set by midnight fudging

    return Assignment.__super__.copyDataFromObject.apply(this, arguments)
  },

  fullDetailsURL() {
    return this.assignment.html_url
  },

  parseStartDate() {
    if (this.assignment.due_at) {
      return fcUtil.wrap(this.assignment.due_at)
    }
  },

  displayTimeString() {
    const datetime = this.originalStart
    if (datetime) {
      return I18n.t('Due: %{dueAt}', {dueAt: this.formatTime(datetime)})
    } else {
      return I18n.t('No Date')
    }
  },

  readableType() {
    return this.readableTypes[this.assignmentType()]
  },

  saveDates(success, error) {
    return this.save(
      {'assignment[due_at]': this.start ? fcUtil.unwrap(this.start).toISOString() : ''},
      success,
      error
    )
  },

  save(params, success, error) {
    $.publish('CommonEvent/assignmentSaved', this)
    return Assignment.__super__.save.apply(this, arguments)
  },

  methodAndURLForSave() {
    let method, url
    if (this.isNewEvent()) {
      method = 'POST'
      url = this.contextInfo.create_assignment_url
    } else {
      method = 'PUT'
      url = $.replaceTags(this.contextInfo.assignment_url, 'id', this.assignment.id)
    }
    return [method, url]
  },

  isCompleted() {
    return (
      this.assignment.user_submitted || (this.isPast() && this.assignment.needs_grading_count === 0)
    )
  }
})
