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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {debounce} from 'lodash'
import * as tz from '../index'
import fallbacks from 'translations/en.json'
import datePickerFormat from '../datePickerFormat'
import {isRTL} from '@canvas/i18n/rtlHelper'

import moment from 'moment'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('datepicker')

const TIME_FORMAT_OPTIONS = {
  hour: 'numeric',
  minute: 'numeric',
}

const DATE_FORMAT_OPTIONS = {
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
}

const DATETIME_FORMAT_OPTIONS = {...DATE_FORMAT_OPTIONS, ...TIME_FORMAT_OPTIONS}

Object.freeze(TIME_FORMAT_OPTIONS)
Object.freeze(DATE_FORMAT_OPTIONS)
Object.freeze(DATETIME_FORMAT_OPTIONS)

// for tests only
export {TIME_FORMAT_OPTIONS, DATE_FORMAT_OPTIONS, DATETIME_FORMAT_OPTIONS}

function formatter(zone, formatOptions = DATETIME_FORMAT_OPTIONS) {
  const options = {...formatOptions}
  if (zone) options.timeZone = zone
  return new Intl.DateTimeFormat(ENV.LOCALE || navigator.language, options)
}

let datepickerDefaults

function computeDatepickerDefaults() {
  datepickerDefaults = {
    constrainInput: false,
    showOn: 'button',
    buttonText: '<i class="icon-calendar-month"></i>',
    buttonImageOnly: false,
    disableButton: false,

    // localization values understood by $.datepicker
    isRTL: isRTL(),
    get prevText() {
      return I18n.t('prevText', 'Prev')
    }, // title text for previous month icon
    get nextText() {
      return I18n.t('nextText', 'Next')
    }, // title text for next month icon
    get firstDay() {
      return I18n.t('first_day_index', '0')
    }, // first day of the week (Sun = 0)
    get showMonthAfterYear() {
      try {
        return I18n.lookup('date.formats.medium_month').slice(0, 2) === '%Y'
      } catch {
        // eslint-disable-next-line no-console
        console.warn('WARNING Missing required datepicker keys in locale file')
        return false // Assume English
      }
    }, // is it "year month" in this locale as opposed to "month year"?
  }

  // Fill in the rest from the locale date keys; if anything throws
  // an error, then something is missing from the locale file, so just
  // fall back to English
  try {
    datepickerDefaults.dateFormat = datePickerFormat(I18n.lookup('date.formats.medium')) // date format for input field
    datepickerDefaults.monthNames = I18n.lookup('date.month_names').slice(1) // names of months
    datepickerDefaults.monthNamesShort = I18n.lookup('date.abbr_month_names').slice(1) // abbreviated names of months
    datepickerDefaults.dayNames = I18n.lookup('date.day_names') // title text for column headings
    datepickerDefaults.dayNamesShort = I18n.lookup('date.abbr_day_names') // title text for column headings
    datepickerDefaults.dayNamesMin = I18n.lookup('date.datepicker.column_headings') // column headings for days (Sunday = 0)
  } catch {
    // eslint-disable-next-line no-console
    console.warn(
      'WARNING Missing required datepicker keys in locale file, using US English datepicker'
    )
    datepickerDefaults.dateFormat = datePickerFormat(fallbacks['date.formats.medium'])
    datepickerDefaults.monthNames = fallbacks['date.month_names'].slice(1)
    datepickerDefaults.monthNamesShort = fallbacks['date.abbr_month_names'].slice(1)
    datepickerDefaults.dayNames = fallbacks['date.day_names']
    datepickerDefaults.dayNamesShort = fallbacks['date.abbr_day_names']
    datepickerDefaults.dayNamesMin = fallbacks['date.datepicker.column_headings']
  }
}

// adds datepicker and suggest functionality to the specified $field
export default class DatetimeField {
  constructor($field, options = {}) {
    ;['alertScreenreader', 'setFromValue', 'setDatetime', 'setTime', 'setDate'].forEach(
      m => (this[m] = this[m].bind(this))
    )
    let $wrapper
    this.$field = $field
    this.$field.data({instance: this})

    this.processTimeOptions(options)
    if (this.showDate) $wrapper = this.addDatePicker(options)

    this.addSuggests($wrapper || this.$field, options)
    if (options.addHiddenInput) this.addHiddenInput()

    this.localLabel = options.localLabel || I18n.t('#helpers.local_time', 'Local')
    this.contextLabel = options.contextLabel || I18n.t('#helpers.course_time', 'Course')

    // when the input changes, update this object from the new value
    this.$field.bind('change focus blur keyup', this.setFromValue)
    this.$field.bind('change focus keyup', this.alertScreenreader)

    // debounce so that as we flash interpretations of what they're typing, we
    // do it once when they finish (or at least pause) typing instead of every
    // keystroke. see comment in alertScreenreader for why we debounce this
    // instead of alertScreenreader itself.
    this.debouncedSRFME = debounce($.screenReaderFlashMessageExclusive, 1000)

    // process initial value
    if (options.time) {
      this.parseValue(options.time)
      this.update()
    } else {
      this.setFromValue()
    }
  }

  processTimeOptions(options) {
    // default undefineds to false
    let {timeOnly, dateOnly} = options
    const {alwaysShowTime} = options

    // as long as options.timeOnly and options.dateOnly aren't both true,
    // showDate || showTime will always be true; i.e. not showDate implies
    // showTime, and vice versa. that's a nice property, so let's enforce it
    // (treating the provision as both as the provision of neither)
    /* eslint-disable no-console */
    if (timeOnly && dateOnly) {
      console.warn('DatetimeField instantiated with both timeOnly and dateOnly true.')
      console.warn('Treating both as false instead.')
      timeOnly = dateOnly = false
    }
    /* eslint-enable no-console */

    this.showDate = !timeOnly
    this.allowTime = !dateOnly
    this.alwaysShowTime = this.allowTime && (timeOnly || alwaysShowTime)
  }

  addDatePicker(options) {
    this.$field.wrap('<div class="input-append" />')
    const $wrapper = this.$field.parent('.input-append')
    // See if we were given an ISO initial value so we don't have to try to parse
    const initialValue = this.$field.attr('data-initial-value')
    if (initialValue) {
      this.$field.removeAttr('data-initial-value')
      this.$field.data('inputdate', new Date(initialValue))
    }
    if (!this.isReadonly()) {
      const datepickerOptions = $.extend(
        {},
        this.getDatepickerDefaults(),
        {
          timePicker: this.allowTime,
          beforeShow: () => this.$field.trigger('detachTooltip'),
          onClose: () => this.$field.trigger('reattachTooltip'),
          firstDay: moment.localeData(ENV.MOMENT_LOCALE).firstDayOfWeek(),
        },
        options.datepicker
      )
      this.$field.datepicker(datepickerOptions)

      // TEMPORARY FIX: Hide from aria screenreader until the jQuery UI datepicker is updated for accessibility.
      const $datepickerButton = this.$field.next()
      $datepickerButton.attr('aria-hidden', 'true')
      $datepickerButton.attr('tabindex', '-1')
      if (options.disableButton) $datepickerButton.prop('disabled', true)
    }
    return $wrapper
  }

  addSuggests($sibling, options = {}) {
    if (this.isReadonly()) return
    this.contextTimezone = options.contextTimezone || ENV.CONTEXT_TIMEZONE
    this.$suggest = $('<div class="datetime_suggest" />').insertAfter($sibling)
    if (this.contextTimezone != null && this.contextTimezone !== ENV.TIMEZONE) {
      this.$contextSuggest = $('<div class="datetime_suggest" />').insertAfter(this.$suggest)
    }
  }

  addHiddenInput() {
    this.$hiddenInput = $('<input type="hidden">').insertAfter(this.$field)
    this.$hiddenInput.attr('name', this.$field.attr('name'))
    this.$hiddenInput.val(this.$field.val())
    this.$field.removeAttr('name')
    this.$field.data('hiddenInput', this.$hiddenInput)
  }

  // public API
  setDate(date) {
    if (!this.showDate) {
      this.implicitDate = date
      // replace the date portion of what we have with the date we just received
      // Current computed value is in the 'iso8601' data as an ISO string, so
      // let's mash the time from that with the new date we're being given,
      const newDate = date.toISOString().substr(0, 10)
      const oldTime = (this.$field.data('iso8601') || date.toISOString()).substr(10)
      const timeWithNewDate = `${newDate}${oldTime}`
      this.$field.data('inputdate', timeWithNewDate)
      return this.setFromValue()
    } else {
      return this.setFormattedDatetime(date, DATE_FORMAT_OPTIONS)
    }
  }

  setTime(date) {
    return this.setFormattedDatetime(date, TIME_FORMAT_OPTIONS)
  }

  setDatetime(date) {
    return this.setFormattedDatetime(date, DATETIME_FORMAT_OPTIONS)
  }

  // private API
  setFromValue(e) {
    const inputdate = this.$field.data('inputdate')
    if (typeof e !== 'undefined' && ['focus', 'blur'].includes(e.type) && !inputdate) return
    this.parseValue()
    this.update()
    this.updateSuggest(e?.type === 'keyup') // only show suggestions when typing
  }

  normalizeValue(value) {
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

  parseValue(val) {
    if (typeof val === 'undefined' && this.$field.data('inputdate')) {
      const inputdate = this.$field.data('inputdate')
      this.datetime = inputdate instanceof Date ? inputdate : new Date(inputdate)
      this.blank = false
      this.invalid = this.datetime === null
      this.$field.data('inputdate', null)
    } else {
      const previousDate = this.datetime
      if (val) {
        this.setFormattedDatetime(val, TIME_FORMAT_OPTIONS)
      }
      const value = this.normalizeValue(this.$field.val())
      this.datetime = tz.parse(value)
      this.blank = !value
      this.invalid = !this.blank && this.datetime === null
      // If the date is invalid, revert to the previous date
      if (this.invalid) {
        this.datetime = previousDate
      }
    }
    if (this.datetime && !this.showDate && this.implicitDate) {
      this.datetime = tz.mergeTimeAndDate(this.datetime, this.implicitDate)
    }
    this.fudged = $.fudgeDateForProfileTimezone(this.datetime)
    this.showTime = this.alwaysShowTime || (this.allowTime && !tz.isMidnight(this.datetime))
  }

  setFormattedDatetime(datetime, format) {
    if (datetime) {
      this.blank = false
      this.$field.data('inputdate', datetime.toISOString())
      this.datetime = datetime
      this.fudged = $.fudgeDateForProfileTimezone(this.datetime)
      const fmtr = formatter(ENV.TIMEZONE, format)
      this.$field.val(fmtr.format(this.datetime))
    } else {
      this.blank = true
      this.datetime = null
      this.fudged = null
      this.$field.val('')
    }
    this.invalid = false
    this.showTime = this.alwaysShowTime || (this.allowTime && !tz.isMidnight(this.datetime))
    this.update()
    this.updateSuggest(false)
  }

  update() {
    this.updateData()
    this.updateAria()
  }

  updateData() {
    const iso8601 = (this.datetime && this.datetime.toISOString()) || ''
    this.$field.data({
      'unfudged-date': this.datetime,
      date: this.fudged,
      iso8601,
      blank: this.blank,
      invalid: this.invalid,
    })

    if (this.$hiddenInput) {
      this.$hiddenInput.val(this.fudged?.toISOString())
    }

    // date_fields and time_fields don't have timepicker data fields
    if (!(this.showDate && this.allowTime)) return

    if (this.invalid || this.blank || !this.showTime) {
      this.$field.data({
        'time-hour': null,
        'time-minute': null,
        'time-ampm': null,
      })
    } else {
      const parts = formatter(ENV.TIMEZONE).formatToParts(this.datetime)
      this.$field.data({
        'time-hour': parts.find(e => e.type === 'hour').value,
        'time-minute': parts.find(e => e.type === 'minute').value,
        'time-ampm': parts.find(e => e.type === 'dayPeriod')?.value || null,
      })
    }
  }

  updateSuggest(show) {
    if (this.isReadonly()) return

    let localText = this.formatSuggest()
    this.screenreaderAlert = localText
    if (this.$contextSuggest) {
      let contextText = this.formatSuggestContext()
      if (contextText) {
        localText = `${this.localLabel}: ${localText}`
        contextText = `${this.contextLabel}: ${contextText}`
        this.screenreaderAlert = `${localText}\n${contextText}`
      }
      this.$contextSuggest.text(contextText).show()
    }
    this.$suggest.toggleClass('invalid_datetime', this.invalid).text(localText)
    if (show || this.$contextSuggest || this.invalid) {
      this.$suggest.show()
      return
    }
    this.$suggest.hide()
    if (this.$contextSuggest) this.$contextSuggest.hide()
    this.screenreaderAlert = ''
  }

  alertScreenreader() {
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

  updateAria() {
    this.$field.attr('aria-invalid', !!this.invalid)
  }

  intlFormatType() {
    if (this.showDate && this.showTime) return DATETIME_FORMAT_OPTIONS
    if (this.showDate) return DATE_FORMAT_OPTIONS
    return TIME_FORMAT_OPTIONS
  }

  formatSuggest() {
    if (this.invalid) return this.parseError
    if (this.blank) return ''
    return formatter(ENV.TIMEZONE, this.intlFormatType()).format(this.datetime)
  }

  formatSuggestContext() {
    if (this.invalid || !this.showTime || this.blank) return ''
    return formatter(this.contextTimezone, this.intlFormatType()).format(this.datetime)
  }

  isReadonly() {
    return !!this.$field.attr('readonly')
  }

  getDatepickerDefaults() {
    if (!datepickerDefaults) computeDatepickerDefaults()

    return datepickerDefaults
  }

  get parseError() {
    return I18n.t('errors.not_a_date', "That's not a date!")
  }
}
