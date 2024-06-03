//
// Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@instructure/moment-utils'
import {fudgeDateForProfileTimezone} from '@instructure/moment-utils'
import {changeTimezone} from '@instructure/moment-utils/changeTimezone'
import 'jqueryui/datepicker'
import '@canvas/jquery-keycodes'
import renderDatepickerTime from '../react/components/render-datepicker-time'

const I18n = useI18nScope('instructure_date_and_time')

$.datepicker.oldParseDate = $.datepicker.parseDate
$.datepicker.parseDate = function (format, value, settings) {
  // try parsing with tz.parse first. if it can, its return is an unfudged
  // value, but the datepicker expects a fudged one, so fudge it. if it can't
  // parse it, fallback to the datepicker's original parseDate (which returns
  // already fudged)
  const datetime = tz.parse(value)
  if (datetime) {
    return fudgeDateForProfileTimezone(datetime)
  } else {
    return $.datepicker.oldParseDate(format, value, settings)
  }
}
$.datepicker._generateDatepickerHTML = $.datepicker._generateHTML
$.datepicker._generateHTML = function (inst) {
  let html = $.datepicker._generateDatepickerHTML(inst)
  if (inst.settings.timePicker) {
    html += renderDatepickerTime(inst.input)
  }
  return html
}
$.fn.realDatepicker = $.fn.datepicker
const _originalSelectDay = $.datepicker._selectDay
$.datepicker._selectDay = function (id, month, year, td) {
  const target = $(id)
  if ($(td).hasClass(this._unselectableClass) || this._isDisabledDatepicker(target[0])) {
    return
  }
  const inst = this._getInst(target[0])
  if (inst.settings.timePicker && !$.datepicker.okClicked && !inst._keyEvent) {
    const origVal = inst.inline
    inst.inline = true
    $.data(target, 'datepicker', inst)
    _originalSelectDay.call(this, id, month, year, td)
    inst.inline = origVal
    $.data(target, 'datepicker', inst)
  } else {
    _originalSelectDay.call(this, id, month, year, td)
  }
}
$.fn.datepicker = function (options) {
  options = {...options}
  options.prevOnSelect = options.onSelect
  options.onSelect = function (text, picker) {
    if (options.prevOnSelect) {
      options.prevOnSelect.call(this, text, picker)
    }
    const $div = picker.dpDiv
    const $input = picker.input
    // We want to pass the inputdate metadata back into our target because
    // if there has been a change via the datepicker, there's no guarantee
    // that the formatted value we are about to jam into the input field
    // itself is in fact parsable by tz. This is already true in momentjs
    // for many of our locales, and will only continue to diverge as we
    // increase adoption of the Intl.DateTimeFormat stuff. DatetimeField
    // is smart enough to always use the inputdate metadata if it's there
    // preferentially to trying to use tz.parse.
    const inputdate = new Date(
      picker.selectedYear,
      picker.selectedMonth,
      parseInt(picker.selectedDay, 10)
    )
    const format = {month: 'short', day: 'numeric', year: 'numeric'}

    const hr =
      $div.find('.ui-datepicker-time-hour').val() ||
      $input.data('time-hour') ||
      $input.data('timeHour')
    const min =
      $div.find('.ui-datepicker-time-minute').val() ||
      $input.data('time-minute') ||
      $input.data('timeMinute')
    const ampm =
      $div.find('.ui-datepicker-time-ampm').val() ||
      $input.data('time-ampm') ||
      $input.data('timeAmpm')
    if (hr || min) {
      let numericHr = parseInt(hr || '0', 10)
      const numericMin = parseInt(min || '0', 10)

      if (tz.hasMeridiem()) {
        let isPM = numericHr > 12 // definitely PM if the hour value is past noon
        numericHr %= 12

        // Check for the "post meridian" marker in this locale (ignoring
        // any punctuation) to see if need to add 12 to the hour to get
        // the final 24-hour value. Note that hours past 12 are always
        // considered PM no matter what the am/pm selection is.
        if (!isPM && ampm) {
          const pmMatch = new RegExp(I18n.t('#time.pm').replace(/[-/:. ]/g, ''), 'i')
          isPM = pmMatch.test(ampm.replace(/[-/:. ]/g, ''))
        }

        if (isPM) numericHr = (numericHr + 12) % 24
      }

      inputdate.setHours(numericHr)
      inputdate.setMinutes(numericMin)
      format.hour = 'numeric'
      format.minute = 'numeric'
    }
    // We have to be careful because Date objects are always in the browser's
    // timezone, not necessarily what's reflected by ENV.TIMEZONE.
    $input.data('inputdate', changeTimezone(inputdate, {desiredTZ: ENV.TIMEZONE}))
    const formatter = new Intl.DateTimeFormat(ENV.LOCALE || navigator.language, format)
    $input.val(formatter.format(inputdate)).change()
  }
  if (!$.fn.datepicker.timepicker_initialized) {
    $(document).on('click', '.ui-datepicker-ok', () => {
      const cur = $.datepicker._curInst
      const inst = cur
      const sel = $(
        `td.${$.datepicker._dayOverClass}, td.${$.datepicker._currentClass}`,
        inst.dpDiv
      )
      if (sel[0]) {
        $.datepicker.okClicked = true
        $.datepicker._selectDay(cur.input[0], inst.selectedMonth, inst.selectedYear, sel[0])
        $.datepicker.okClicked = false
      } else {
        $.datepicker._hideDatepicker(null, $.datepicker._get(inst, 'duration'))
      }
    })
    $(document)
      .on('change keypress focus blur', '.ui-datepicker-time-hour', function (event) {
        const cur = $.datepicker._curInst
        if (cur) {
          const $this = $(this)
          let val = $this.val()
          const $ampm = $this.closest('.ui-datepicker-time').find('.ui-datepicker-time-ampm')
          if (event.type === 'change' && val && $ampm.length && !$ampm.val()) {
            let ampmVal
            if (parseInt(val, 10) === 0) {
              ampmVal = I18n.t('#time.am', 'am')
              val = '12'
              $this.val(val)
            } else {
              ampmVal = I18n.t('#time.pm', 'pm')
            }
            $ampm.val(ampmVal)
            cur.input.data('time-ampm', ampmVal)
          }
          cur.input.data('time-hour', val)
        }
      })
      .on('change keypress focus blur', '.ui-datepicker-time-minute', function () {
        const cur = $.datepicker._curInst
        if (cur) {
          const val = $(this).val()
          cur.input.data('time-minute', val)
        }
      })
      .on('change keypress focus blur', '.ui-datepicker-time-ampm', function () {
        const cur = $.datepicker._curInst
        if (cur) {
          const val = $(this).val()
          cur.input.data('time-ampm', val)
        }
      })
    $(document).on(
      'mousedown',
      '.ui-datepicker-time-hour,.ui-datepicker-time-minute,.ui-datepicker-time-ampm',
      function () {
        $(this).focus()
      }
    )
    $(document).on(
      'change keypress focus blur',
      '.ui-datepicker-time-hour,.ui-datepicker-time-minute,.ui-datepicker-time-ampm',
      event => {
        if (event.keyCode && event.keyCode === 13) {
          const cur = $.datepicker._curInst
          const inst = cur
          const sel = $(
            'td.' + $.datepicker._dayOverClass + ', td.' + $.datepicker._currentClass,
            inst.dpDiv
          )
          if (sel[0]) {
            $.datepicker.okClicked = true
            $.datepicker._selectDay(cur.input[0], inst.selectedMonth, inst.selectedYear, sel[0])
            $.datepicker.okClicked = false
          } else {
            $.datepicker._hideDatepicker(null, $.datepicker._get(inst, 'duration'))
          }
        } else if (event.keyCode && event.keyCode === 27) {
          $.datepicker._hideDatepicker(null, '')
        }
      }
    )
    $.fn.datepicker.timepicker_initialized = true
  }
  this.realDatepicker(options)
  $(document).data('last_datepicker', this)
  return this
}

// add bootstrap's .btn class to the button that opens a datepicker
$.datepicker._triggerClass += ' btn'
