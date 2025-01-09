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

import $ from 'jquery'
import {useScope as createI18nScope} from '@canvas/i18n'
import timeBlockRowTemplate from '../jst/TimeBlockRow.handlebars'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import datePickerFormat from '@instructure/moment-utils/datePickerFormat'
import '../fcMomentHandlebarsHelpers' // make sure fcMomentToString and fcMomentToDateString are available to TimeBlockRow.handlebars
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'

const I18n = createI18nScope('calendar')

export default class TimeBlockRow {
  constructor(TimeBlockList, data) {
    if (data == null) data = {}
    this.TimeBlockList = TimeBlockList
    this.locked = data.locked
    let timeoutId = null
    data.date = data.date || data.start
    this.$row = $(timeBlockRowTemplate(data)).bind({
      focusin: () => {
        clearTimeout(timeoutId)
        this.focus()
      },
      focusout: () => {
        timeoutId = setTimeout(() => this.$row.removeClass('focused'), 50)
      },
    })

    this.$date = this.$row.find("input[name='date']")
    this.$start_time = this.$row.find("input[name='start_time']")
    this.$end_time = this.$row.find("input[name='end_time']")

    renderDatetimeField(this.$date, {
      dateOnly: true,
      datepicker: {dateFormat: datePickerFormat(I18n.t('#date.formats.default'))},
      newSuggestionDesign: true,
    })
    this.$date.change(this.validate)
    renderDatetimeField($(this.$start_time), {
      timeOnly: true,
      newSuggestionDesign: true,
    })
    this.$start_time.change(this.validate)
    renderDatetimeField($(this.$end_time), {
      timeOnly: true,
      newSuggestionDesign: true,
    })
    this.$end_time.change(this.validate)

    if (this.locked) this.$row.find('button').prop('disabled', true)

    this.$row.find('.delete-block-link').click(this.remove)
  }

  remove = event => {
    if (event) event.preventDefault()

    this.$row.remove()
    // tell the list that I was removed
    this.TimeBlockList.rowRemoved(this)
    // Send the keyboard focus to a reasonable location.
    $('input.date_field:visible').focus()
  }

  focus = () => {
    this.$row.addClass('focused')
    // scroll all the way down if it is the last row
    // (so the datetime suggest shows up in scrollable area)
    if (this.$row.is(':last-child')) {
      this.$row.parents('.time-block-list-body-wrapper').scrollTop(9999)
    }
  }

  showInlineError = ($el, message) => {
    const error_box = $el.next('.datetime_suggest')
    error_box.addClass('invalid_datetime')
    error_box.children('.error-message').children('span').text(message)
    error_box.show()
  }

  clearInlineError = $el => {
    const error_box = $el.next('.datetime_suggest')
    error_box.removeClass('invalid_datetime')
    error_box.hide()
  }

  validate = () => {
    // for locked row, all values are valid, regardless of actual value
    if (this.locked) {
      this.$date.toggleClass('error', false)
      this.$start_time.toggleClass('error', false)
      this.$end_time.toggleClass('error', false)
      return true
    }

    // initialize field validity by parse validity
    const dateValid = !this.$date.data('invalid')
    let startValid = !this.$start_time.data('invalid')
    let endValid = !this.$end_time.data('invalid')

    // also make sure start is before end
    const start = this.startAt()
    const end = this.endAt()
    if (start && end && end <= start) {
      this.showInlineError(
        this.$start_time,
        I18n.t('end_before_start_error', 'Start time must be before end time'),
      )
      startValid = false
    } else {
      this.clearInlineError(this.$start_time)
    }

    // and end is in the future
    if (end && end < fcUtil.now()) {
      this.showInlineError(
        this.$end_time,
        I18n.t('ends_in_past_error', 'You cannot create an appointment slot that ends in the past'),
      )
      endValid = false
    } else {
      this.clearInlineError(this.$end_time)
    }

    // toggle error class on each as appropriate
    this.$date.toggleClass('error', !dateValid)
    this.$end_time.toggleClass('error', !endValid)
    this.$start_time.toggleClass('error', !startValid)

    // valid if all are valid
    return dateValid && startValid && endValid
  }

  timeToDate(date, time) {
    if (!date || !time) return

    // set all three values at once to handle potential
    // conflicts in how month rollover happens
    time.year(date.year())
    time.month(date.month())
    time.date(date.date())

    return time
  }

  startAt() {
    const date = fcUtil.wrap(this.$date.data('unfudged-date'))
    const time = fcUtil.wrap(this.$start_time.data('unfudged-date'))
    return this.timeToDate(date, time)
  }

  endAt() {
    const date = fcUtil.wrap(this.$date.data('unfudged-date'))
    const time = fcUtil.wrap(this.$end_time.data('unfudged-date'))
    return this.timeToDate(date, time)
  }

  getData() {
    return [this.startAt(), this.endAt(), !!this.locked]
  }

  blank() {
    return (
      this.$date.data('blank') && this.$start_time.data('blank') && this.$end_time.data('blank')
    )
  }

  incomplete() {
    return (
      !this.blank() &&
      (this.$date.data('blank') || this.$start_time.data('blank') || this.$end_time.data('blank'))
    )
  }
}
