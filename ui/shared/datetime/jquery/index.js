/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import * as tz from '../index'
import htmlEscape from '@instructure/html-escape'
import * as dateFunctions from '../date-functions'
import {changeTimezone} from '../changeTimezone'
import DatetimeField from './DatetimeField'
import renderDatepickerTime from '../react/components/render-datepicker-time'
import '@canvas/jquery-keycodes'
import 'jqueryui/datepicker'

const I18n = useI18nScope('instructure_date_and_time')

// these functions were extracted to @canvas/datetime/date-functions so they
// could more easily be reused by non-jQuery-reliant code. See their
// definitions there for more usage info.
$.fudgeDateForProfileTimezone = dateFunctions.fudgeDateForProfileTimezone
$.unfudgeDateForProfileTimezone = dateFunctions.unfudgeDateForProfileTimezone
$.sameYear = dateFunctions.sameYear
$.sameDate = dateFunctions.sameDate
$.dateString = dateFunctions.dateString
$.timeString = dateFunctions.timeString
$.datetimeString = dateFunctions.datetimeString
$.discussionsDatetimeString = dateFunctions.discussionsDatetimeString
$.friendlyDate = dateFunctions.friendlyDate
$.friendlyDatetime = dateFunctions.friendlyDatetime

$.datepicker.oldParseDate = $.datepicker.parseDate
$.datepicker.parseDate = function (format, value, settings) {
  // try parsing with tz.parse first. if it can, its return is an unfudged
  // value, but the datepicker expects a fudged one, so fudge it. if it can't
  // parse it, fallback to the datepicker's original parseDate (which returns
  // already fudged)
  const datetime = tz.parse(value)
  if (datetime) {
    return $.fudgeDateForProfileTimezone(datetime)
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
$.fn.date_field = function (options) {
  options = {...options}
  options.dateOnly = true
  this.datetime_field(options)
  return this
}
$.fn.time_field = function (options) {
  options = {...options}
  options.timeOnly = true
  this.datetime_field(options)
  return this
}

// add bootstrap's .btn class to the button that opens a datepicker
$.datepicker._triggerClass += ' btn'

$.fn.datetime_field = function (options) {
  options = {...options}
  this.each(function () {
    const $field = $(this)
    if (!$field.hasClass('datetime_field_enabled')) {
      $field.addClass('datetime_field_enabled')
      new DatetimeField($field, options)
    }
  })
  return this
}

/* Based loosely on:
    jQuery ui.timepickr - 0.6.5
    http://code.google.com/p/jquery-utils/

    (c) Maxime Haineault <haineault@gmail.com>
    http://haineault.com

    MIT License (http://www.opensource.org/licenses/mit-license.php */
$.fn.timepicker = function () {
  let $picker = $('#time_picker')
  if ($picker.length === 0) {
    $picker = $._initializeTimepicker()
  }
  this.each(function () {
    $(this)
      .focus(function () {
        const offset = $(this).offset()
        const height = $(this).outerHeight()
        const width = $(this).outerWidth()
        $picker = $('#time_picker')
        $picker
          .css({
            left: -1000,
            height: 'auto',
            width: 'auto',
          })
          .show()
        const pickerHeight = $picker.outerHeight()
        const pickerWidth = $picker.outerWidth()
        $picker
          .css({
            top: offset.top + height,
            left: offset.left,
          })
          .end()
        $('#time_picker .time_slot')
          .removeClass('ui-state-highlight')
          .removeClass('ui-state-active')
        $picker.data('attached_to', $(this)[0])
        const windowHeight = $(window).height()
        const windowWidth = $(window).width()
        const scrollTop = window.scrollY
        if (offset.top + height - scrollTop + pickerHeight > windowHeight) {
          $picker.css({
            top: offset.top - pickerHeight,
          })
        }
        if (offset.left + pickerWidth > windowWidth) {
          $picker.css({
            left: offset.left + width - pickerWidth,
          })
        }
        $('#time_picker').hide().slideDown()
      })
      .blur(function () {
        if ($('#time_picker').data('attached_to') === $(this)[0]) {
          $('#time_picker').data('attached_to', null)
          $('#time_picker')
            .hide()
            .find('.time_slot.ui-state-highlight')
            .removeClass('ui-state-highlight')
        }
      })
      .keycodes('esc return', function () {
        $(this).triggerHandler('blur')
      })
      .keycodes('ctrl+up ctrl+right ctrl+left ctrl+down', function (event) {
        if ($('#time_picker').data('attached_to') !== $(this)[0]) {
          return
        }
        event.preventDefault()
        const $current = $('#time_picker .time_slot.ui-state-highlight:first')
        const time = $($('#time_picker').data('attached_to')).val()
        let hr = 12
        let min = '00'
        let ampm = 'pm'
        let idx
        if (time && time.length >= 7) {
          hr = time.substring(0, 2)
          min = time.substring(3, 5)
          ampm = time.substring(5, 7)
        }
        if ($current.length === 0) {
          idx = parseInt(time, 10) - 1
          if (Number.isNaN(Number(idx))) {
            idx = 0
          }
          $('#time_picker .time_slot').eq(idx).triggerHandler('mouseover')
          return
        }
        let $parent
        if (event.keyString === 'ctrl+up') {
          $parent = $current.parent('.widget_group')
          idx = $parent.children('.time_slot').index($current)
          if ($parent.hasClass('ampm_group')) {
            idx = min / 15
          } else if ($parent.hasClass('minute_group')) {
            idx = parseInt(hr, 10) - 1
          }
          $parent.prev('.widget_group').find('.time_slot').eq(idx).triggerHandler('mouseover')
        } else if (event.keyString === 'ctrl+right') {
          $current.next('.time_slot').triggerHandler('mouseover')
        } else if (event.keyString === 'ctrl+left') {
          $current.prev('.time_slot').triggerHandler('mouseover')
        } else if (event.keyString === 'ctrl+down') {
          $parent = $current.parent('.widget_group')
          idx = $parent.children('.time_slot').index($current)
          const $list = $parent.next('.widget_group').find('.time_slot')
          idx = Math.min(idx, $list.length - 1)
          if ($parent.hasClass('hour_group')) {
            idx = min / 15
          } else if ($parent.hasClass('minute_group')) {
            idx = ampm === 'am' ? 0 : 1
          }
          $list.eq(idx).triggerHandler('mouseover')
        }
      })
  })
  return this
}
$._initializeTimepicker = function () {
  const $picker = $(document.createElement('div'))
  $picker.attr('id', 'time_picker').css({
    position: 'absolute',
    display: 'none',
  })
  let pickerHtml = "<div class='widget_group hour_group'>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>01</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>02</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>03</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>04</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>05</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>06</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>07</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>08</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>09</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>10</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>11</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>12</div>"
  pickerHtml += "<div class='clear'></div>"
  pickerHtml += '</div>'
  pickerHtml += "<div class='widget_group minute_group'>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>00</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>15</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>30</div>"
  pickerHtml += "<div class='ui-widget ui-state-default time_slot'>45</div>"
  pickerHtml += "<div class='clear'></div>"
  pickerHtml += '</div>'
  pickerHtml += "<div class='widget_group ampm_group'>"
  pickerHtml +=
    "<div class='ui-widget ui-state-default time_slot'>" +
    htmlEscape(I18n.t('#time.am', 'am')) +
    '</div>'
  pickerHtml +=
    "<div class='ui-widget ui-state-default time_slot'>" +
    htmlEscape(I18n.t('#time.pm', 'pm')) +
    '</div>'
  pickerHtml += "<div class='clear'></div>"
  pickerHtml += '</div>'
  $picker.html(pickerHtml)
  $('body').append($picker)
  $picker
    .find('.time_slot')
    .mouseover(function () {
      $picker.find('.time_slot.ui-state-highlight').removeClass('ui-state-highlight')
      $(this).addClass('ui-state-highlight')
      const $field = $($picker.data('attached_to') || 'none')
      const time = $field.val()
      let hr = 12
      let min = '00'
      let ampm = 'pm'
      if (time && time.length >= 7) {
        hr = time.substring(0, 2)
        min = time.substring(3, 5)
        ampm = time.substring(5, 7)
      }
      const val = $(this).text()
      if (val > 0 && val <= 12) {
        hr = val
      } else if (val === 'am' || val === 'pm') {
        ampm = val
      } else {
        min = val
      }
      $field.val(hr + ':' + min + ampm)
    })
    .mouseout(function () {
      $(this).removeClass('ui-state-highlight')
    })
    .mousedown(function (event) {
      event.preventDefault()
      $(this).triggerHandler('mouseover')
      $(this).removeClass('ui-state-highlight').addClass('ui-state-active')
    })
    .mouseup(function () {
      $(this).removeClass('ui-state-active')
    })
    .click(function (event) {
      event.preventDefault()
      $(this).triggerHandler('mouseover')
      if ($picker.data('attached_to')) {
        $($picker.data('attached_to')).focus()
      }
      $picker.stop().hide().data('attached_to', null)
    })
  return $picker
}

export default $
