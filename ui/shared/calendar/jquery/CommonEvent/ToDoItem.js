/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import fcUtil from '../fcUtil'
import CommonEvent from './CommonEvent'
import {extend} from '@canvas/util/legacyCoffeesScriptHelpers'
import '@canvas/datetime/jquery'
import '@canvas/jquery/jquery.instructure_misc_helpers'

const I18n = useI18nScope('calendar')

extend(ToDoItem, CommonEvent)

export default function ToDoItem(data, contextInfo, actualContextInfo) {
  ToDoItem.__super__.constructor.call(this, data, contextInfo, actualContextInfo)
  this.eventType = 'todo_item'
  switch (this.object.plannable_type) {
    case 'wiki_page':
      this.deleteConfirmation = I18n.t('Are you sure you want to delete this page?')
      break
    case 'discussion_topic':
      this.deleteConfirmation = I18n.t('Are you sure you want to delete this discussion?')
      break
    default:
      this.deleteConfirmation = I18n.t('Are you sure you want to delete this To Do item?')
  }
}

Object.assign(ToDoItem.prototype, {
  copyDataFromObject(data) {
    // on original load, data comes from the planner items API
    // but after editing an item, we get the wiki pages / discussion topics API update result
    if (!data.hasOwnProperty('plannable')) {
      data = this.mergeEditResult(data)
    }

    data.start_at = data.plannable.todo_date
    data.end_at = data.plannable.todo_date
    data.all_day = false
    data.title = data.plannable.title
    data.url = data.html_url

    this.object = this.calendarEvent = data
    this.object.id = this.id = `${data.plannable_type}_${data.plannable_id}`
    this.title = data.title || 'Untitled'
    this.start = this.parseStartDate()
    this.end = undefined
    this.allDay = data.all_day
    // see originalStart in super's copyDataFromObject
    if (this.end) this.originalEndDate = fcUtil.clone(this.end)
    this.lockedTitle = this.object.parent_event_id != null
    this.description = data.description
    this.addClass(`group_${this.contextCode()}`)
    this.deleteObjectURL = this.apiUrl()
    this.editUrl = `${data.url}/edit`

    return ToDoItem.__super__.copyDataFromObject.apply(this, arguments)
  },

  endDate() {
    return this.originalEndDate
  },

  parseStartDate() {
    if (this.calendarEvent.start_at) {
      return fcUtil.wrap(this.calendarEvent.start_at)
    }
    return null
  },

  displayTimeString() {
    return this.formatTime(this.startDate())
  },

  readableType() {
    return this.readableTypes[this.object.plannable_type]
  },

  fullDetailsURL() {
    return this.object.html_url
  },

  saveParams(todo_date, title) {
    const date_param = fcUtil.unwrap(todo_date).toISOString()
    const params = {}
    if (this.object.plannable_type === 'wiki_page') {
      params['wiki_page[student_planner_checkbox]'] = true
      params['wiki_page[student_todo_at]'] = date_param
      if (title) {
        params['wiki_page[title]'] = title
      }
    } else {
      params.todo_date = date_param
      if (title) {
        params.title = title
      }
    }
    return params
  },

  // called at the end of a drag and drop operation
  saveDates(success, error) {
    return this.save(this.saveParams(this.start), success, error)
  },

  methodAndURLForSave() {
    return ['PUT', this.apiUrl()]
  },

  urlFragment() {
    switch (this.object.plannable_type) {
      case 'wiki_page':
        return `pages/${encodeURIComponent(this.object.plannable.url)}`
      default:
        return `${encodeURIComponent(this.object.plannable_type)}s/${encodeURIComponent(
          this.object.plannable_id
        )}`
    }
  },

  apiUrl() {
    return `${this.contextApiPrefix()}/${this.urlFragment()}`
  },

  mergeEditResult(data) {
    // here we need to preserve the necessary fields that the planner api returns outside of plannable
    // (additionally we need to preserve the transformed ones from EventDataSource)
    const {
      type,
      context_code,
      all_context_codes,
      plannable_type,
      plannable_id,
      planner_override,
      new_activity,
      submissions,
      html_url,
    } = this.object

    return {
      type,
      context_code,
      all_context_codes,
      plannable_type,
      plannable_id,
      planner_override,
      new_activity,
      submissions,
      html_url,
      plannable_date: data.todo_date,
      plannable: data, // replace the plannable with the wiki page / discussion topic API update result
    }
  },
})
