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
import $ from 'jquery'
import tz from 'timezone'
import htmlEscape from 'str/htmlEscape'
import editPlannerNoteTemplate from 'jst/calendar/editPlannerNote'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_forms'
import 'jquery.instructure_misc_helpers'
import 'vendor/date'
import fcUtil from '../util/fcUtil'
import commonEventFactory from '../calendar/commonEventFactory'
import ValidatedFormView from '../views/ValidatedFormView'
import '../calendar/fcMomentHandlebarsHelpers'

export default class EditPlannerNoteDetails extends ValidatedFormView {

  events = {
    ...EditPlannerNoteDetails.prototype.events,
    'change .context_id': 'contextChange'
  }
  template = editPlannerNoteTemplate

  constructor(selector, event, contextChangeCB, closeCB) {
    super({
      title: event.title,
      contexts: event.possibleContexts().filter((context) =>
        // to avoid confusion over the audience of the planner note,
        // don't offer to create new planner notes linked to courses the user teaches
        context && context.asset_string && (
          context.asset_string === event.contextCode() ||
          context.asset_string.startsWith('user_') ||
          ENV.CALENDAR.MANAGE_CONTEXTS.indexOf(context.asset_string) < 0
        )
      ),
      date: event.startDate(),
      details: htmlEscape(event.description)
    })

    this.onSaveFail = this.onSaveFail.bind(this)
    this.onSaveSuccess = this.onSaveSuccess.bind(this)
    this.getFormData = this.getFormData.bind(this)
    this.setupTimeAndDatePickers = this.setupTimeAndDatePickers.bind(this)
    this.contextChange = this.contextChange.bind(this)
    this.setContext = this.setContext.bind(this)
    this.activate = this.activate.bind(this)

    this.event = event
    this.contextChangeCB = contextChangeCB
    this.closeCB = closeCB

    this.currentContextInfo = null

    $(selector).append(this.render().el)

    this.setupTimeAndDatePickers()
    this.$el.find('select.context_id').triggerHandler('change', false)

    // show context select if the event allows moving between calendars
    if (this.event.can_change_context) {
      if (!this.event.isNewEvent()) {
        this.setContext(this.event.object.context_code)
      }
    } else {
      this.$el.find('.context_select').hide()
    }

    this.model = this.event
  }

  submit(e) {
    const data = this.getFormData()
    if (this.event.isNewEvent()) {
      data.contextInfo = this.event.contextInfo
      data.context_code = this.event.contextInfo.asset_string
      this.model = commonEventFactory(data, this.event.possibleContexts())
    } else if (
      this.event.can_change_context &&
      data.context_code !== this.event.object.context_code
    ) {
      // need to update this.event so it is cached in the right calendar (aka context_code)
      this.event.old_context_code = this.event.object.context_code
      this.event.removeClass(`group_${this.event.old_context_code}`)
      this.event.object.context_code = data.context_code
      this.event.contextInfo = this.contextInfoForCode(data.context_code)
    }

    return super.submit(e)
  }

  contextInfoForCode(code) {
    return this.event.possibleContexts().find(context => context.asset_string === code) || null
  }

  activate() {
    return this.$el.find('select.context_id').change()
  }

  setContext(newContext) {
    this.$el
      .find('select.context_id')
      .val(newContext)
      .triggerHandler('change', false)
  }

  contextChange(jsEvent, propagate) {
    const context = $(jsEvent.target).val()
    this.currentContextInfo = this.contextInfoForCode(context)
    this.event.contextInfo = this.currentContextInfo
    if (this.currentContextInfo == null) {
      return
    }

    if (propagate !== false) {
      this.contextChangeCB(context)
    }
  }

  // TODO: when we can create planner notes from the calendar
  // # Update the edit and more option urls
  // moreOptionsHref = null
  // if @event.isNewEvent()
  //   moreOptionsHref = @currentContextInfo.new_planner_note_url
  // else
  //   moreOptionsHref = @event.fullDetailsURL() + '/edit'
  // @$el.find(".more_options_link").attr 'href', moreOptionsHref

  setupTimeAndDatePickers() {
    // select the appropriate fields
    const $date = this.$el.find('.date_field')
    const $time = this.$el.find(".time_field.note_time")

    // set them up as appropriate variants of datetime_field
    $date.datetime_field({
      datepicker: {
        dateFormat: datePickerFormat(I18n.t('#date.formats.medium_with_weekday'))
      },
      dateOnly: true
    })
    $time.time_field()

    // fill initial values of each field according to @event
    const due = fcUtil.unwrap(this.event.startDate())
    $date.data('instance').setDate(due)
    $time.data('instance').setTime(this.event.isNewEvent() ? null : due)
  }

  getFormData() {
    const data = super.getFormData()

    const params = {
      title: data.title,
      todo_date: data.date,
      details: data.details,
      id: this.event.object.id,
      type: 'planner_note',
      context_code: data.context_code
    }
    // check if input box was cleared for explicitly undated
    if (params.todo_date) {
      const { time } = data
      let due_at = params.todo_date.toString('yyyy-MM-dd')
      if (time) {
        due_at += time.toString(' HH:mm')
      } else {
        due_at += ' 23:59'
      }

      params.todo_date = tz.parse(due_at)
    }

    if (data.context_code.match(/^course_/)) {
      // is in a course's calendar
      params.context_type = 'Course'
      params.course_id = data.context_code.replace('course_', '')
    } else {
      // is in the user's calendar
      if (!this.event.isNewEvent()) {
        params.course_id = ''
      }
      params.user_id = data.context_code.replace('user_', '')
    }

    return params
  }

  onSaveSuccess() {
    return this.closeCB()
  }

  onSaveFail(xhr) {
    this.disableWhileLoadingOpts = {}
    return EditPlannerNoteDetails.__super__.onSaveFail.call(this, xhr)
  }

  validateBeforeSave(data, errors) {
    errors = this._validateTitle(data, errors)  // eslint-disable-line no-param-reassign
    errors = this._validateDate(data, errors)   // eslint-disable-line no-param-reassign
    return errors
  }

  _validateTitle(data, errors) {
    if (!data.title || $.trim(data.title.toString()).length === 0) {
      errors.title = [{message: I18n.t('Title is required!')}]  // eslint-disable-line no-param-reassign
    }
    return errors
  }

  _validateDate(data, errors) {
    if (!data.todo_date || $.trim(data.todo_date.toString()).length === 0) {
      errors.date = [{message: I18n.t('Date is required!')}]  // eslint-disable-line no-param-reassign
    }
    return errors
  }
}
