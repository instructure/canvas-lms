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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import editToDoItemTemplate from '../../jst/editToDoItem.handlebars'
import datePickerFormat from '@canvas/datetime/datePickerFormat'
import '@canvas/datetime/jquery'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import 'date-js'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import '../../fcMomentHandlebarsHelpers'

const I18n = useI18nScope('calendar')

export default class EditToDoItemDetails extends ValidatedFormView {
  template = editToDoItemTemplate

  constructor(selector, event, contextChangeCB, closeCB) {
    super({
      title: event.title,
      contexts: event.possibleContexts(),
      date: event.startDate(),
      details: htmlEscape(event.description),
    })

    this.event = event
    this.closeCB = closeCB

    this.currentContextInfo = null

    $(selector).append(this.render().el)

    this.setupTimeAndDatePickers()

    this.model = this.event
  }

  submit(e) {
    return super.submit(e)
  }

  activate() {
    let title
    switch (this.event.object.plannable_type) {
      case 'wiki_page':
        title = I18n.t('Page')
        break
      case 'discussion_topic':
        title = I18n.t('Discussion')
        break
      default:
        title = I18n.t('To Do Item')
    }
    $('#edit_event_tabs .edit_todo_item_option').text(title)

    $('#edit_todo_item_form_holder .more_options_link').attr('href', this.event.editUrl)
  }

  setupTimeAndDatePickers() {
    // select the appropriate fields
    const $date = this.$el.find('.date_field')
    const $time = this.$el.find('.time_field.note_time')

    // set them up as appropriate variants of datetime_field
    $date.datetime_field({
      datepicker: {
        dateFormat: datePickerFormat(I18n.t('#date.formats.default')),
      },
      dateOnly: true,
    })
    $time.time_field()

    // fill initial values of each field according to @event
    const due = fcUtil.unwrap(this.event.startDate())
    $date.data('instance').setDate(due)
    $time.data('instance').setTime(due)
  }

  getFormData() {
    const data = super.getFormData()

    const todo_date = data.date
    if (todo_date) {
      const {time} = data
      let due_at = todo_date.toString('yyyy-MM-dd')
      if (time) {
        due_at += time.toString(' HH:mm')
      } else {
        due_at += ' 23:59'
      }

      return this.event.saveParams(fcUtil.wrap(due_at), data.title)
    } else {
      return data
    }
  }

  onSaveSuccess() {
    return this.closeCB()
  }

  onSaveFail(xhr) {
    this.disableWhileLoadingOpts = {}
    return EditToDoItemDetails.__super__.onSaveFail.call(this, xhr)
  }

  validateBeforeSave(data, errors) {
    errors = this._validateTitle(data, errors)
    errors = this._validateDate(data, errors)
    return errors
  }

  _validateTitle(data, errors) {
    const title = data.title || data['wiki_page[title]']
    if (!title || $.trim(title.toString()).length === 0) {
      errors.title = [{message: I18n.t('Title is required!')}]
    }
    return errors
  }

  _validateDate(data, errors) {
    const todo_date = data.todo_date || data['wiki_page[student_todo_at]']
    if (!todo_date || $.trim(todo_date.toString()).length === 0) {
      errors.date = [{message: I18n.t('Date is required!')}]
    }
    return errors
  }
}
