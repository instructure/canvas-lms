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
import {useScope as useI18nScope} from '@canvas/i18n'
import timeBlockRowTemplate from '../jst/TimeBlockRow.handlebars'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import datePickerFormat from '@canvas/datetime/datePickerFormat'
import '../fcMomentHandlebarsHelpers' // make sure fcMomentToString and fcMomentToDateString are available to TimeBlockRow.handlebars

const I18n = useI18nScope('calendar')

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

    const $date_field = this.$date.date_field({
      datepicker: {dateFormat: datePickerFormat(I18n.t('#date.formats.default'))},
    })
    $date_field.change(this.validate)
    this.$start_time.time_field().change(this.validate)
    this.$end_time.time_field().change(this.validate)

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

  validate = () => {
    // clear previous errors
    const remove = el => el && el.remove()
    remove(this.$date.data('associated_error_box'))
    this.$date.toggleClass('error', false)
    remove(this.$start_time.data('associated_error_box'))
    this.$start_time.toggleClass('error', false)
    remove(this.$end_time.data('associated_error_box'))
    this.$end_time.toggleClass('error', false)

    // for locked row, all values are valid, regardless of actual value
    if (this.locked) {
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
      this.$start_time.errorBox(
        I18n.t('end_before_start_error', 'Start time must be before end time')
      )
      startValid = false
    }

    // and end is in the future
    if (end && end < fcUtil.now()) {
      this.$end_time.errorBox(
        I18n.t('ends_in_past_error', 'You cannot create an appointment slot that ends in the past')
      )
      endValid = false
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
