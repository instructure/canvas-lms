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
import _ from 'underscore'
import tz from 'timezone'
import editCalendarEventTemplate from 'jst/calendar/editCalendarEvent'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_forms'
import 'jquery.instructure_misc_helpers'
import 'vendor/date'
import commonEventFactory from '../calendar/commonEventFactory'
import coupleTimeFields from '../util/coupleTimeFields'
import fcUtil from '../util/fcUtil'
import '../calendar/fcMomentHandlebarsHelpers'

export default class EditCalendarEventDetails {
  constructor(selector, event, contextChangeCB, closeCB) {
    this.event = event
    this.contextChangeCB = contextChangeCB
    this.closeCB = closeCB
    this.currentContextInfo = null
    this.$form = $(
      editCalendarEventTemplate({
        title: this.event.title,
        contexts: this.event.possibleContexts(),
        lockedTitle: this.event.lockedTitle,
        location_name: this.event.location_name,
        date: this.event.startDate()
      })
    )
    $(selector).append(this.$form)

    this.setupTimeAndDatePickers()

    this.$form.submit(this.formSubmit)
    this.$form.find('.more_options_link').click(this.moreOptionsClick)
    this.$form.find('select.context_id').change(this.contextChange)
    this.$form.find('#duplicate_event').change(this.duplicateCheckboxChanged)
    this.$form.find('select.context_id').triggerHandler('change', false)

    // show context select if the event allows moving between calendars
    if (this.event.can_change_context) {
      if (!this.event.isNewEvent()) {
        this.setContext(this.event.object.context_code)
      }
    } else {
      this.$form.find('.context_select').hide()
    }

    // duplication only works on create
    if (!this.event.isNewEvent()) {
      this.$form.find('.duplicate_event_row, .duplicate_event_toggle_row').hide()
    }
  }

  contextInfoForCode(code) {
    return this.event.possibleContexts().find(context => context.asset_string === code) || null
  }

  activate = () => this.$form.find('select.context_id').change()

  getFormData = () => {
    let date
    let data = this.$form.getFormData({object_name: 'calendar_event'})
    data = _.omit(
      data,
      'date',
      'start_time',
      'end_time',
      'duplicate',
      'duplicate_count',
      'duplicate_interval',
      'duplicate_frequency',
      'append_iterator'
    )

    // check if input box was cleared for explicitly undated
    if (this.$form.find('input[name=date]').val()) {
      date = this.$form.find('input[name=date]').data('date')
    }
    if (date) {
      const start_time = this.$form.find('input[name=start_time]').data('date')
      let start_at = date.toString('yyyy-MM-dd')
      if (start_time) start_at += start_time.toString(' HH:mm')

      data.start_at = tz.parse(start_at)

      const end_time = this.$form.find('input[name=end_time]').data('date')
      let end_at = date.toString('yyyy-MM-dd')
      if (end_time) end_at += end_time.toString(' HH:mm')
      data.end_at = tz.parse(end_at)
    }

    const duplicate = this.$form.find('#duplicate_event').prop('checked')
    if (duplicate) {
      data.duplicate = {
        count: this.$form.find('#duplicate_count').val(),
        interval: this.$form.find('#duplicate_interval').val(),
        frequency: this.$form.find('#duplicate_frequency').val(),
        append_iterator: this.$form.find('#append_iterator').is(':checked')
      }
    }

    return data
  }

  moreOptionsClick = jsEvent => {
    if (this.event.object.parent_event_id) return

    jsEvent.preventDefault()
    const params = {return_to: window.location.href}

    const data = this.getFormData()

    // override parsed input with user input (for 'More Options' only)
    data.start_date = this.$form.find('input[name=date]').val()
    if (data.start_date) {
      data.start_date = $.unfudgeDateForProfileTimezone(data.start_date).toISOString()
    }

    data.start_time = this.$form.find('input[name=start_time]').val()
    data.end_time = this.$form.find('input[name=end_time]').val()

    if (data.title) params.title = data.title
    if (data.location_name) params.location_name = data.location_name
    if (data.start_date) params.start_date = data.start_date
    if (data.start_time) params.start_time = data.start_time
    if (data.end_time) params.end_time = data.end_time
    if (data.duplicate) params.duplicate = data.duplicate

    const pieces = $(jsEvent.target)
      .attr('href')
      .split('#')
    pieces[0] += `?${$.param(params)}`
    window.location.href = pieces.join('#')
  }

  setContext(newContext) {
    this.$form
      .find('select.context_id')
      .val(newContext)
      .triggerHandler('change', false)
  }

  contextChange = (jsEvent, propagate) => {
    const context = $(jsEvent.target).val()
    this.currentContextInfo = this.contextInfoForCode(context)
    this.event.contextInfo = this.currentContextInfo
    if (this.currentContextInfo == null) return

    if (propagate !== false) this.contextChangeCB(context)

    // Update the edit and more option urls
    let moreOptionsHref = null
    if (this.event.isNewEvent()) {
      moreOptionsHref = this.currentContextInfo.new_calendar_event_url
    } else {
      moreOptionsHref = `${this.event.fullDetailsURL()}/edit`
    }
    this.$form.find('.more_options_link').attr('href', moreOptionsHref)
  }

  duplicateCheckboxChanged = (jsEvent, _propagate) =>
    this.enableDuplicateFields(jsEvent.target.checked)

  enableDuplicateFields = shouldEnable => {
    const elts = this.$form.find('.duplicate_fields').find('input')
    const disableValue = !shouldEnable
    elts.prop('disabled', disableValue)
    return this.$form.find('.duplicate_event_row').toggle(!disableValue)
  }

  setupTimeAndDatePickers() {
    // select the appropriate fields
    const $date = this.$form.find('.date_field')
    const $start = this.$form.find('.time_field.start_time')
    const $end = this.$form.find('.time_field.end_time')

    // set them up as appropriate variants of datetime_field
    $date.date_field({
      datepicker: {dateFormat: datePickerFormat(I18n.t('#date.formats.medium_with_weekday'))}
    })
    $start.time_field()
    $end.time_field()

    // fill initial values of each field according to @event
    const start = fcUtil.unwrap(this.event.startDate())
    const end = fcUtil.unwrap(this.event.endDate())

    $start.data('instance').setTime(this.event.allDay ? null : start)
    $end.data('instance').setTime(this.event.allDay ? null : end)

    // couple start and end times so that end time will never precede start
    return coupleTimeFields($start, $end, $date)
  }

  formSubmit = jsEvent => {
    jsEvent.preventDefault()

    const data = this.getFormData()
    const location_name = data.location_name || ''

    const params = {
      'calendar_event[title]': data.title != null ? data.title : this.event.title,
      'calendar_event[start_at]': data.start_at ? data.start_at.toISOString() : '',
      'calendar_event[end_at]': data.end_at ? data.end_at.toISOString() : '',
      'calendar_event[location_name]': location_name
    }

    if (data.duplicate != null) params['calendar_event[duplicate]'] = data.duplicate

    if (this.event.isNewEvent()) {
      params['calendar_event[context_code]'] = data.context_code
      const objectData = {
        calendar_event: {
          title: params['calendar_event[title]'],
          start_at: data.start_at ? data.start_at.toISOString() : null,
          end_at: data.end_at ? data.end_at.toISOString() : null,
          location_name,
          context_code: this.$form.find('.context_id').val()
        }
      }
      const newEvent = commonEventFactory(objectData, this.event.possibleContexts())
      newEvent.save(params)
    } else {
      this.event.title = params['calendar_event[title]']
      // event unfudges/unwraps values when sending to server (so wrap here)
      this.event.start = fcUtil.wrap(data.start_at)
      this.event.end = fcUtil.wrap(data.end_at)
      this.event.location_name = location_name
      if (this.event.can_change_context && data.context_code !== this.event.object.context_code) {
        this.event.old_context_code = this.event.object.context_code
        this.event.removeClass(`group_${this.event.old_context_code}`)
        this.event.object.context_code = data.context_code
        this.event.contextInfo = this.contextInfoForCode(data.context_code)
        params['calendar_event[context_code]'] = data.context_code
      }
      this.event.save(params)
    }

    return this.closeCB()
  }
}
