/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import CommonEvent from './CommonEvent'
import fcUtil from '../fcUtil'
import {extend} from '@canvas/util/legacyCoffeesScriptHelpers'
import '@canvas/jquery/jquery.instructure_misc_helpers'

const I18n = createI18nScope('calendar')

const deleteConfirmation = I18n.t(
  'prompts.delete_sub_assignment_override',
  'Are you sure you want to delete this event? Deleting this event will also delete the associated assignment and other checkpoints associated with the assignment.',
)

extend(SubAssignmentOverride, CommonEvent)
export default function SubAssignmentOverride(data, _contextInfo) {
  SubAssignmentOverride.__super__.constructor.apply(this, arguments)
  this.eventType = 'sub_assignment_override'
  this.deleteConfirmation = deleteConfirmation
  this.deleteURL = data.sub_assignment.html_url
  this.addClass('sub_assignment_override')
}

Object.assign(SubAssignmentOverride.prototype, {
  copyDataFromObject(data) {
    if (data.sub_assignment != null) {
      this.copyDataFromSubAssignment(data.sub_assignment)
      this.copyDataFromSubAssignmentOverride(data.sub_assignment_override)
    } else {
      this.copyDataFromSubAssignmentOverride(data)
    }
    this.title = I18n.t('%{title} (%{overrideTitle})', {
      title: this.assignment.name || I18n.t('Untitled'),
      overrideTitle: this.override.title,
    })
    this.object = this.override
    this.addClass(`group_${this.contextCode()}`)
    return SubAssignmentOverride.__super__.copyDataFromObject.apply(this, arguments)
  },

  copyDataFromSubAssignment(subAssignment) {
    this.assignment = subAssignment
    this.lock_explanation = null // not set at sub assignment level
    this.description = this.assignment.description
    this.start = this.parseStartDate()
    this.end = null // in case it got set by midnight fudging
  },

  copyDataFromSubAssignmentOverride(override) {
    this.override = override
    this.id = `sub_assignment_override_${this.override.id}`
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

  isCompleted() {
    return (
      this.assignment.user_submitted || (this.isPast() && this.assignment.needs_grading_count === 0)
    )
  },
})
