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

import {useScope as useI18nScope} from '@canvas/i18n'
import CommonEvent from './CommonEvent'
import fcUtil from '../fcUtil'
import {extend} from '@canvas/util/legacyCoffeesScriptHelpers'
import '@canvas/datetime/jquery'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('calendar')

const deleteConfirmation = I18n.t(
  'prompts.delete_override',
  'Are you sure you want to delete this assignment override?'
)

extend(AssignmentOverride, CommonEvent)
export default function AssignmentOverride(data, contextInfo) {
  AssignmentOverride.__super__.constructor.apply(this, arguments)
  this.eventType = 'assignment_override'
  this.deleteConfirmation = deleteConfirmation
  this.deleteUrl = contextInfo.assignment_url
  this.addClass('assignment_override')
}

Object.assign(AssignmentOverride.prototype, {
  copyDataFromObject(data) {
    if (data.assignment != null) {
      this.copyDataFromAssignment(data.assignment)
      this.copyDataFromOverride(data.assignment_override)
    } else {
      this.copyDataFromOverride(data)
    }

    this.title = `${this.assignment.name} (${this.override.title})`
    this.object = this.override
    this.addClass(`group_${this.contextCode()}`)
    return AssignmentOverride.__super__.copyDataFromObject.apply(this, arguments)
  },

  copyDataFromAssignment(assignment) {
    this.assignment = assignment
    this.lock_explanation = this.assignment.lock_explanation
    this.description = this.assignment.description
    this.start = this.parseStartDate()
    this.end = null // in case it got set by midnight fudging
  },

  copyDataFromOverride(override) {
    this.override = override
    this.id = `override_${this.override.id}`
    this.assignment.due_at = this.override.due_at
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

  updateAssignmentTitle(title) {
    this.assignment.title = title
    const titleContext = this.title.match(/\(.+\)$/)[0]
    this.title = `${title} ${titleContext}`
  },

  saveDates(success, error) {
    return this.save(
      {'assignment_override[due_at]': this.start ? fcUtil.unwrap(this.start).toISOString() : ''},
      success,
      error
    )
  },

  methodAndURLForSave() {
    const url = replaceTags(this.contextInfo.assignment_override_url, {
      assignment_id: this.assignment.id,
      id: this.override.id,
    })
    return ['PUT', url]
  },

  isCompleted() {
    return (
      this.assignment.user_submitted || (this.isPast() && this.assignment.needs_grading_count === 0)
    )
  },
})
