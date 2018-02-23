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
import htmlEscape from 'str/htmlEscape'
import fcUtil from '../util/fcUtil'
import commonEventFactory from '../calendar/commonEventFactory'
import ValidatedFormView from '../views/ValidatedFormView'
import editPlannerNoteTemplate from 'jst/calendar/editPlannerNote'
import wrapper from 'jst/EmptyDialogFormWrapper'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'
import {extend} from '../legacyCoffeesScriptHelpers'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_forms'
import 'jquery.instructure_misc_helpers'
import 'vendor/date'
import '../calendar/fcMomentHandlebarsHelpers'

extend(EditPlannerNoteDetails, ValidatedFormView)

export default function EditPlannerNoteDetails() {
  this.onSaveFail = this.onSaveFail.bind(this)
  this.onSaveSuccess = this.onSaveSuccess.bind(this)
  this.getFormData = this.getFormData.bind(this)
  this.setupTimeAndDatePickers = this.setupTimeAndDatePickers.bind(this)
  this.contextChange = this.contextChange.bind(this)
  this.setContext = this.setContext.bind(this)
  this.activate = this.activate.bind(this)
  this.submitNote = this.submitNote.bind(this)
  return EditPlannerNoteDetails.__super__.constructor.apply(this, arguments)
}

Object.assign(EditPlannerNoteDetails.prototype, {
  events: {
    ...EditPlannerNoteDetails.prototype.events,
    'click .save_note': 'submitNote',
    'change .context_id': 'contextChange'
  },
  template: editPlannerNoteTemplate,
  wrapper,

  initialize(selector, event, contextChangeCB, closeCB) {
    this.event = event
    this.contextChangeCB = contextChangeCB
    this.closeCB = closeCB
    EditPlannerNoteDetails.__super__.initialize.call(this, {
      title: this.event.title,
      contexts: this.event.possibleContexts(),
      date: this.event.startDate(),
      details: htmlEscape(this.event.description)
    })
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
  },

  submitNote(e) {
    const data = this.getFormData()
    if (this.event.isNewEvent()) {
      data.contextInfo = this.event.contextInfo
      data.context_code = this.event.contextInfo.asset_string
      this.model = commonEventFactory(data, this.event.possibleContexts())
    } else if (
      this.event.can_change_context &&
      data.context_code !== this.event.object.context_code
    ) {
      // need to update @event so it is cached in the right calendar (aka context_code)
      this.event.old_context_code = this.event.object.context_code
      this.event.removeClass(`group_${this.event.old_context_code}`)
      this.event.object.context_code = data.context_code
      this.event.contextInfo = this.contextInfoForCode(data.context_code)
    }

    return this.submit(e)
  },

  contextInfoForCode(code) {
    return this.event.possibleContexts().find(context => context.asset_string === code) || null
  },

  activate() {
    return this.$el.find('select.context_id').change()
  },

  setContext(newContext) {
    this.$el
      .find('select.context_id')
      .val(newContext)
      .triggerHandler('change', false)
  },

  contextChange(jsEvent, propagate) {
    const context = $(jsEvent.target).val()
    this.currentContextInfo = this.contextInfoForCode(context)
    this.event.contextInfo = this.currentContextInfo
    if (this.currentContextInfo == null) {
      return
    }

    if (propagate !== false) {
      return this.contextChangeCB(context)
    }
  },

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
    // $start = @$el.find(".time_field.start_time")
    // $end = @$el.find(".time_field.end_time")

    // set them up as appropriate variants of datetime_field
    $date.datetime_field({
      datepicker: {
        dateFormat: datePickerFormat(
          this.event.allDay
            ? I18n.t('#date.formats.medium_with_weekday')
            : I18n.t('#date.formats.full_with_weekday')
        )
      }
    })
    // $start.time_field()
    // $end.time_field()

    // fill initial values of each field according to @event
    const start = fcUtil.unwrap(this.event.startDate())
    // end = fcUtil.unwrap(@event.endDate())

    return $date.data('instance', start)
  },
  // $start.data('instance').setTime(if @event.allDay then null else start)
  // $end.data('instance').setTime(if @event.allDay then null else end)
  //
  // # couple start and end times so that end time will never precede start
  // coupleTimeFields($start, $end, $date)

  getFormData() {
    const data = EditPlannerNoteDetails.__super__.getFormData.apply(this, arguments)

    const params = {
      title: data.title,
      todo_date: data.date ? data.date.toISOString() : '',
      details: data.details,
      id: this.event.object.id,
      type: 'planner_note',
      context_code: data.context_code
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
  },

  onSaveSuccess() {
    return this.closeCB()
  },

  onSaveFail(xhr) {
    this.disableWhileLoadingOpts = {}
    return EditPlannerNoteDetails.__super__.onSaveFail.call(this, xhr)
  },

  validateBeforeSave(data, errors) {
    errors = this._validateTitle(data, errors)
    errors = this._validateDate(data, errors)
    return errors
  },

  _validateTitle(data, errors) {
    if (!data.title || $.trim(data.title.toString()).length === 0) {
      errors.title = [{message: I18n.t('Title is required!')}]
    }
    return errors
  },

  _validateDate(data, errors) {
    if (!data.todo_date || $.trim(data.todo_date.toString()).length === 0) {
      errors.date = [{message: I18n.t('Date is required!')}]
    }
    return errors
  }
})
