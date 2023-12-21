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
import I18n from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/datetime/jquery'
import '@canvas/util/templateData' /* fillTemplateData */
import 'jqueryui/datepicker'
import moment from 'moment'

function makeDate(date) {
  return {
    day: date.getDate(),
    month: date.getMonth(),
    year: date.getFullYear(),
  }
}

export function changeMonth($month, change) {
  const monthNames = I18n.lookup('date.month_names')
  let data = {}
  let month
  let year
  let current = null
  if (typeof change === 'string') {
    current = $.datepicker.oldParseDate('mm/dd/yy', change)
    if (current) {
      current.setDate(1)
    }
  }
  if (!current) {
    month = parseInt($month.find('.month_number').text(), 10)
    year = parseInt($month.find('.year_number').text(), 10)
    current = new Date(year, month + change - 1, 1)
  }
  data = {
    month_name: monthNames[current.getMonth() + 1],
    month_number: current.getMonth() + 1,
    year_number: current.getFullYear(),
  }
  $month.fillTemplateData({data})
  const firstDayOfWeek = moment.localeData(ENV.MOMENT_LOCALE).firstDayOfWeek()
  let date = new Date()
  const today = makeDate(date)
  const firstDayOfMonth = makeDate(current)
  date = current
  date.setDate(0)
  date.setDate(date.getDate() - date.getDay() + firstDayOfWeek)
  const firstDayOfSquare = makeDate(date)
  let lastDayOfPreviousMonth = null
  if (firstDayOfMonth.day !== firstDayOfSquare.day) {
    date.setDate(1)
    date.setMonth(date.getMonth() + 1)
    date.setDate(0)
    lastDayOfPreviousMonth = {
      day: date.getDate(),
      month: firstDayOfSquare.month,
      year: firstDayOfSquare.year,
    }
    date.setDate(1)
    date.setMonth(date.getMonth() + 1)
  }
  date.setMonth(current.getMonth() + 1)
  date.setDate(0)
  const lastDayOfMonth = {
    day: date.getDate(),
    month: firstDayOfMonth.month,
    year: firstDayOfMonth.yearh,
  }
  date.setDate(date.getDate() + 1)
  date.setDate(date.getDate() + (6 - date.getDay()))
  date.setDate(date.getDate() + 7)
  const lastDayOfSquare = makeDate(date)
  let $days = $month.data('days')
  if (!$days) {
    $days = $month.find('.calendar_day_holder')
    $month.data('days', $days)
  }
  if ($month.hasClass('mini_month')) {
    $days = $month.find('.day')
  }
  $month.find('.calendar_event').remove()
  let idx = 0
  let day = firstDayOfSquare.day
  month = firstDayOfSquare.month
  year = firstDayOfSquare.year
  while (day <= lastDayOfSquare.day || month !== lastDayOfSquare.month) {
    const $day = $days.eq(idx)
    if ($day.length > 0) {
      const classes = $day.attr('class').split(' ')
      const class_names = []
      for (let i = 0; i < classes.length; i++) {
        if (classes[i].indexOf('date_') === 0) {
          // no-op
        } else {
          class_names.push(classes[i])
        }
      }
      $day.attr('class', class_names.join(' '))
    }
    $day.show().addClass('visible').parents('tr').show().addClass('visible')
    data = {
      day_number: day,
    }
    const month_number = month < 9 ? `0${month + 1}` : month + 1
    const day_number = day < 10 ? `0${day}` : day
    let id = `day_${year}_${month_number}_${day_number}`
    if ($month.hasClass('mini_month')) {
      id = `mini_${id}`
    }
    $day
      .attr('id', id)
      .addClass(`date_${month_number}_${day_number}_${year}`)
      .find('.day_number')
      .text(day)
      .attr('title', `${month_number}/${day_number}/${year}`)
      .addClass(`date_${month_number}_${day_number}_${year}`) // left here because I don't know what it'll break...

    // update a11y label
    const monthName = monthNames[month + 1]
    $day.find('span.screenreader-only:first-child').text(`${day} ${monthName} ${year}`)

    let $div = $day.children('div')
    if ($month.hasClass('mini_month')) {
      $div = $day
    }
    $div.removeClass('current_month other_month next_month previous_month today')
    if (month === firstDayOfMonth.month) {
      $div.addClass('current_month')
    } else {
      $div.addClass('other_month')
      if (firstDayOfMonth.month === (month + 1) % 12) {
        $div.addClass('previous_month')
      } else {
        $div.addClass('next_month')
      }
    }
    if (month === today.month && day === today.day && year === today.year) {
      $div.addClass('today')
    }
    day++
    idx++
    if (
      (lastDayOfPreviousMonth &&
        day > lastDayOfPreviousMonth.day &&
        month === lastDayOfPreviousMonth.month) ||
      (day > lastDayOfMonth.day && month === lastDayOfMonth.month)
    ) {
      month += 1
      if (month >= 12) {
        month -= 12
        year++
      }
      day = 1
    }
  }
  while (idx < $days.length) {
    const $day_ = $days.eq(idx)
    $day_.parents('tr').hide().removeClass('visible')
    $day_.hide().removeClass('visible')
    idx++
  }
  if (!$month.hasClass('mini_month')) {
    // no-op
  }
}
