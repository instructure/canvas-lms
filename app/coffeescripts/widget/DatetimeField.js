//
// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!datepicker'
import $ from 'jquery'
import {debounce} from 'underscore'
import tz from 'timezone'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'
import {isRTL} from 'jsx/shared/helpers/rtlHelper'

import moment from 'moment'
import 'jquery.instructure_date_and_time'
import '../jquery.rails_flash_notifications'

// adds datepicker and suggest functionality to the specified $field
export default class DatetimeField {
  constructor ($field, options = {}) {
    ['alertScreenreader', 'setFromValue', 'setDatetime', 'setTime', 'setDate'].forEach(m => this[m] = this[m].bind(this))
    let $wrapper
    this.$field = $field
    this.$field.data({instance: this})

    this.processTimeOptions(options)
    if (this.showDate) $wrapper = this.addDatePicker(options)

    this.addSuggests($wrapper || this.$field, options)
    if (options.addHiddenInput) this.addHiddenInput()

    // when the input changes, update this object from the new value
    this.$field.bind('change focus blur keyup', this.setFromValue)
    this.$field.bind('change focus keyup', this.alertScreenreader)

    // debounce so that as we flash interpretations of what they're typing, we
    // do it once when they finish (or at least pause) typing instead of every
    // keystroke. see comment in alertScreenreader for why we debounce this
    // instead of alertScreenreader itself.
    this.debouncedSRFME = debounce($.screenReaderFlashMessageExclusive, 1000)

    // process initial value
    this.setFromValue()
  }

  processTimeOptions (options) {
    // default undefineds to false
    let {timeOnly, dateOnly} = options
    const {alwaysShowTime} = options

    // as long as options.timeOnly and options.dateOnly aren't both true,
    // showDate || showTime will always be true; i.e. not showDate implies
    // showTime, and vice versa. that's a nice property, so let's enforce it
    // (treating the provision as both as the provision of neither)
    if (timeOnly && dateOnly) {
      console.warn('DatetimeField instantiated with both timeOnly and dateOnly true.')
      console.warn('Treating both as false instead.')
      timeOnly = dateOnly = false
    }

    this.showDate = !timeOnly
    this.allowTime = !dateOnly
    this.alwaysShowTime = this.allowTime && (timeOnly || alwaysShowTime)
  }

  addDatePicker (options) {
    this.$field.wrap('<div class="input-append" />')
    const $wrapper = this.$field.parent('.input-append')
    if (!this.isReadonly()) {
      const datepickerOptions = $.extend({}, this.datepickerDefaults(), {
        timePicker: this.allowTime,
        beforeShow: () => this.$field.trigger('detachTooltip'),
        onClose: () => this.$field.trigger('reattachTooltip'),
        firstDay: moment.localeData(ENV.MOMENT_LOCALE).firstDayOfWeek(),
      }, options.datepicker)
      this.$field.datepicker(datepickerOptions)

      // TEMPORARY FIX: Hide from aria screenreader until the jQuery UI datepicker is updated for accessibility.
      const $datepickerButton = this.$field.next()
      $datepickerButton.attr('aria-hidden', 'true')
      $datepickerButton.attr('tabindex', '-1')
      if (options.disableButton) $datepickerButton.attr('disabled', 'true')
    }
    return $wrapper
  }

  addSuggests ($sibling, options = {}) {
    if (this.isReadonly()) return
    this.courseTimezone = options.courseTimezone || ENV.CONTEXT_TIMEZONE
    this.$suggest = $('<div class="datetime_suggest" />').insertAfter($sibling)
    if (this.courseTimezone != null && this.courseTimezone !== ENV.TIMEZONE) {
      this.$courseSuggest = $('<div class="datetime_suggest" />').insertAfter(this.$suggest)
    }
  }

  addHiddenInput () {
    this.$hiddenInput = $('<input type="hidden">').insertAfter(this.$field)
    this.$hiddenInput.attr('name', this.$field.attr('name'))
    this.$hiddenInput.val(this.$field.val())
    this.$field.removeAttr('name')
    this.$field.data('hiddenInput', this.$hiddenInput)
  }

  // public API
  setDate (date) {
    if (!this.showDate) {
      this.implicitDate = date
      return this.setFromValue()
    } else {
      return this.setFormattedDatetime(date, 'date.formats.medium')
    }
  }

  setTime (date) {
    return this.setFormattedDatetime(date, 'time.formats.tiny')
  }

  setDatetime (date) {
    return this.setFormattedDatetime(date, 'date.formats.full')
  }

  // private API
  setFromValue () {
    this.parseValue()
    this.update()
  }

  normalizeValue (value) {
    if (value == null) return value

    // trim leading/trailing whitespace
    value = value.trim()
    if (value === '') return value

    // for anything except time-only fields, that's all we do
    if (this.showDate) return value

    // and for time-only fields, we only modify if it's one or two digits
    if (!value.match(/^\d{1,2}$/)) return value

    // if it has a leading zero, it's always 24 hour time
    if (value.match(/^0/)) return `${value}:00`

    // otherwise, treat things from 1 and 7 as PM, and from 8 and 23 as
    // 24-hour time. >= 24 are not valid hour specifications (nor < 0, but
    // those were caught above, since we only have digits at this point) and
    // are just returned as is
    const parsedValue = parseInt(value, 10)
    if (parsedValue < 0 || parsedValue >= 24) {
      return value
    } else if (parsedValue < 8) {
      return `${parsedValue}pm`
    } else {
      return `${parsedValue}:00`
    }
  }

  parseValue () {
    const value = this.normalizeValue(this.$field.val())
    this.datetime = tz.parse(value)
    if (this.datetime && !this.showDate && this.implicitDate) {
      this.datetime = tz.mergeTimeAndDate(this.datetime, this.implicitDate)
    }
    this.fudged = $.fudgeDateForProfileTimezone(this.datetime)
    this.showTime = this.alwaysShowTime || (this.allowTime && !tz.isMidnight(this.datetime))
    this.blank = !value
    this.invalid = !this.blank && this.datetime === null
  }

  setFormattedDatetime (datetime, format) {
    if (datetime) {
      this.blank = false
      this.datetime = datetime
      this.fudged = $.fudgeDateForProfileTimezone(this.datetime)
      this.$field.val(tz.format(this.datetime, format))
    } else {
      this.blank = true
      this.datetime = null
      this.fudged = null
      this.$field.val('')
    }
    this.invalid = false
    this.showTime = this.alwaysShowTime || (this.allowTime && !tz.isMidnight(this.datetime))
    this.update()
  }

  update (updates) {
    this.updateData()
    this.updateSuggest()
    this.updateAria()
  }

  updateData () {
    const iso8601 = this.datetime && this.datetime.toISOString() || ''
    this.$field.data({
      'unfudged-date': this.datetime,
      date: this.fudged,
      iso8601,
      blank: this.blank,
      invalid: this.invalid
    })

    if (this.$hiddenInput) {
      this.$hiddenInput.val(this.fudged)
    }

    // date_fields and time_fields don't have timepicker data fields
    if (!(this.showDate && this.allowTime)) return

    if (this.invalid || this.blank || !this.showTime) {
      this.$field.data({
        'time-hour': null,
        'time-minute': null,
        'time-ampm': null,
      })
    } else if (tz.useMeridian()) {
      this.$field.data({
        'time-hour': tz.format(this.datetime, '%-l'),
        'time-minute': tz.format(this.datetime, '%M'),
        'time-ampm': tz.format(this.datetime, '%P'),
      })
    } else {
      this.$field.data({
        'time-hour': tz.format(this.datetime, '%-k'),
        'time-minute': tz.format(this.datetime, '%M'),
        'time-ampm': null,
      })
    }
  }

  updateSuggest () {
    if (this.isReadonly()) return

    let localText = this.formatSuggest()
    this.screenreaderAlert = localText
    if (this.$courseSuggest) {
      let courseText = this.formatSuggestCourse()
      if (courseText) {
        localText = this.localLabel + localText
        courseText = this.courseLabel + courseText
        this.screenreaderAlert = `${localText}\n${courseText}`
      }
      this.$courseSuggest.text(courseText)
    }
    this.$suggest.toggleClass('invalid_datetime', this.invalid).text(localText)
  }

  alertScreenreader () {
    // only alert if the value in the field changed (e.g. don't alert on arrow
    // keys). not debouncing around alertScreenreader itself, because if so,
    // the retrieval of val() here gets delayed and can do weird stuff while
    // typing is ongoing
    const alertingFor = this.$field.val()
    if (alertingFor !== this.lastAlertedFor) {
      this.debouncedSRFME(this.screenreaderAlert)
      this.lastAlertedFor = alertingFor
    }
  }

  updateAria () {
    this.$field.attr('aria-invalid', !!this.invalid)
  }

  formatSuggest () {
    if (this.blank) {
      return ''
    } else if (this.invalid) {
      return this.parseError
    } else {
      return tz.format(this.datetime, this.formatString())
    }
  }

  formatSuggestCourse () {
    if (this.blank) {
      return ''
    } else if (this.invalid) {
      return ''
    } else if (this.showTime) {
      return tz.format(this.datetime, this.formatString(), this.courseTimezone)
    } else {
      return ''
    }
  }

  formatString () {
    if (this.showDate && this.showTime) {
      return I18n.t('#date.formats.full_with_weekday')
    } else if (this.showDate) {
      return I18n.t('#date.formats.medium_with_weekday')
    } else {
      return I18n.t('#time.formats.tiny')
    }
  }

  isReadonly () {
    return !!this.$field.attr('readonly')
  }

  datepickerDefaults () {
    return {
      constrainInput: false,
      dateFormat: datePickerFormat(I18n.lookup('date.formats.medium')),
      showOn: 'button',
      buttonText: '<i class="icon-calendar-month"></i>',
      buttonImageOnly: false,
      disableButton: false,

      // localization values understood by $.datepicker
      isRTL: isRTL(),
      prevText: I18n.t('prevText', 'Prev'), // title text for previous month icon
      nextText: I18n.t('nextText', 'Next'), // title text for next month icon
      monthNames: I18n.lookup('date.month_names').slice(1), // names of months
      monthNamesShort: I18n.lookup('date.abbr_month_names').slice(1), // abbreviated names of months
      dayNames: I18n.lookup('date.day_names'), // title text for column headings
      dayNamesShort: I18n.lookup('date.abbr_day_names'), // title text for column headings
      dayNamesMin: I18n.lookup('date.datepicker.column_headings'), // column headings for days (Sunday = 0)
      firstDay: I18n.t('first_day_index', '0'), // first day of the week (Sun = 0)
      showMonthAfterYear: I18n.t('#date.formats.medium_month').slice(0, 2) === '%Y' // "month year" or "year month"
    }
  }
}


DatetimeField.prototype.parseError = I18n.t('errors.not_a_date', "That's not a date!")
DatetimeField.prototype.courseLabel = `${I18n.t('#helpers.course', 'Course')}: `
DatetimeField.prototype.localLabel = `${I18n.t('#helpers.local', 'Local')}: `
