//
// Copyright (C) 2013 - present Instructure, Inc.
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
//

import $ from 'jquery'
import {changeMonth} from '../../jquery/calendar_move' // calendarMonths
import RichContentEditor from '@canvas/rce/RichContentEditor'
import '@canvas/jquery/jquery.instructure_forms' // formSubmit, formErrors
import '@canvas/jquery/jquery.instructure_misc_plugins' // ifExists, showIf
import '@canvas/loading-image'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import '@canvas/datetime/jquery/datepicker'
import easy_student_view from '@canvas/easy-student-view'
import htmlEscape from '@instructure/html-escape'
import {escape} from 'es-toolkit/compat'

RichContentEditor.preloadRemoteModule()

// Highlight mini calendar days matching syllabus events
//    Queries the syllabus event list and highlights the
//    corresponding mini calendar dates.
function highlightDaysWithEvents() {
  const $mini_month = $('.mini_month')
  const $syllabus = $('#syllabus')
  if (!$mini_month || !$syllabus) return

  let events = $mini_month.find('.day.has_event')
  events.removeClass('has_event')
  let wrapper = events.find('.day_wrapper')
  wrapper.removeAttr('role')
  wrapper.removeAttr('tabindex')

  $syllabus.find('tr.date:visible').each(function () {
    const date = $(this).find('.day_date').attr('data-date')
    events = $mini_month.find(`#mini_day_${date}`)
    events.addClass('has_event')
    wrapper = events.find('.day_wrapper')
    wrapper.attr('role', 'link')
    wrapper.attr('tabindex', '0')
  })
}

// Sets highlighting on a given date
//    Removes all highlighting then highlights the given
//    date, if provided.
function highlightDate(date) {
  const $mini_month = $('.mini_month')
  const $syllabus = $('#syllabus')

  $('tr.date.related, .day.related').removeClass('related')
  if (date) {
    if ($mini_month) $mini_month.find(`#mini_day_${date}`).addClass('related')
    if ($syllabus) $syllabus.find(`tr.date.events_${date}`).addClass('related')
  }
}

function highlightRelated(related_id, self) {
  const $syllabus = $('#syllabus')

  $syllabus.find('tr.related_event').removeClass('related_event')
  if (related_id && $syllabus) {
    $syllabus.find(`tr.related-${related_id}`).not(self).addClass('related_event')
  }
}

// Binds to #syllabus dom events
//    Called to bind behaviors to #syllabus after it's rendered.
function bindToSyllabus() {
  const $syllabus = $('#syllabus')
  $syllabus.on('mouseenter mouseleave', 'tr.date', function (ev) {
    let date
    if (ev.type === 'mouseenter') date = $(this).find('.day_date').attr('data-date')
    highlightDate(date)
  })

  $syllabus.on('mouseenter mouseleave', 'tr.date.detail_list', function (ev) {
    let related_id = null
    if (ev.type === 'mouseenter') {
      const classNames = ($(this).attr('class') || '').split(/\s+/)
      classNames.some(c => {
        if (c.substr(0, 8) === 'related-') {
          return (related_id = c.substr(8))
        }
        return false
      })
    }

    highlightRelated(related_id, this)
  })

  highlightDaysWithEvents()

  const todayString = $.datepicker.formatDate('yy_mm_dd', new Date())
  highlightDate(todayString)
}

function selectRow($row) {
  if ($row.length > 0) {
    $('tr.selected').removeClass('selected')
    $row.addClass('selected')
    $('html, body').scrollTo($row)
    $row.find('a').first().focus()
  }
}

function selectDate(date) {
  $('.mini_month .day.selected').removeClass('selected')
  $('.mini_month').find(`#mini_day_${date}`).addClass('selected')
}

// Builds an accessible label for a mini calendar day
//    Constructs a comprehensive aria-label that includes weekday, date,
//    and contextual information (today, other month, events).
function buildDayAriaLabel($td, cellId, currentMonthNumber) {
  const [, , year, month, day] = cellId.split('_')
  const dateObj = new Date(parseInt(year, 10), parseInt(month, 10) - 1, parseInt(day, 10))

  const weekday = dateObj.toLocaleDateString(undefined, {weekday: 'long'})
  const monthName = dateObj.toLocaleDateString(undefined, {month: 'long'})
  const dayNum = dateObj.getDate()
  const yearNum = dateObj.getFullYear()

  let ariaLabel = `${weekday}, ${monthName} ${dayNum}, ${yearNum}`

  // Add contextual information
  if ($td.hasClass('today')) {
    ariaLabel += ', Today'
  }

  if ($td.hasClass('other_month')) {
    const isPrevMonth = parseInt(month, 10) < currentMonthNumber
    ariaLabel += isPrevMonth ? ', Previous month' : ', Next month'
  }

  if ($td.hasClass('has_event')) {
    ariaLabel += ', Has events'
  }

  return ariaLabel
}

// Navigates focus to another day in the mini calendar using arrow keys
//    Handles arrow key navigation with wrapping at calendar boundaries.
//    Supports left/right for adjacent days and up/down for same weekday.
function navigateMiniCalendarDays(key, $currentWrapper, $mini_month) {
  const $allWrappers = $mini_month.find('.mini_calendar_day .day_wrapper[tabindex="0"]')
  const currentIndex = $allWrappers.index($currentWrapper)
  if (currentIndex === -1) return

  let targetIndex = currentIndex
  const totalDays = $allWrappers.length
  const DAYS_PER_WEEK = 7

  switch (key) {
    case 'ArrowLeft':
      targetIndex = currentIndex - 1
      if (targetIndex < 0) targetIndex = totalDays - 1
      break

    case 'ArrowRight':
      targetIndex = currentIndex + 1
      if (targetIndex >= totalDays) targetIndex = 0
      break

    case 'ArrowUp':
      targetIndex = currentIndex - DAYS_PER_WEEK
      if (targetIndex < 0) {
        const column = currentIndex % DAYS_PER_WEEK
        const lastRowStart = Math.floor((totalDays - 1) / DAYS_PER_WEEK) * DAYS_PER_WEEK
        targetIndex = lastRowStart + column
        if (targetIndex >= totalDays) targetIndex = totalDays - DAYS_PER_WEEK + column
      }
      break

    case 'ArrowDown':
      targetIndex = currentIndex + DAYS_PER_WEEK
      if (targetIndex >= totalDays) targetIndex = currentIndex % DAYS_PER_WEEK
      break
  }

  $allWrappers.eq(targetIndex).focus()
}

// Sets up accessibility for mini calendar
//    Removes table semantics for screen readers, adds proper ARIA labels,
//    and enables keyboard navigation for all calendar days.
function setupMiniCalendarAccessibility($mini_month) {
  // Remove table semantics to prevent announcing table structure
  $mini_month.find('table, thead, tbody, tr, th, td').attr('role', 'presentation')

  const currentMonthNumber = parseInt($mini_month.find('.month_number').text(), 10)

  // Make all days keyboard accessible with proper labels
  $mini_month.find('.mini_calendar_day').each(function () {
    const $td = $(this)
    const $wrapper = $td.find('.day_wrapper')
    const cellId = $td.attr('id')

    if (!cellId) return

    const ariaLabel = buildDayAriaLabel($td, cellId, currentMonthNumber)

    // Hide redundant screenreader-only spans to prevent "group" announcements
    $wrapper.find('.screenreader-only').attr('aria-hidden', 'true')

    $wrapper.attr({
      tabindex: '0',
      role: 'button',
      'aria-label': ariaLabel,
    })
  })

  // Keyboard navigation for days
  $mini_month.off('keydown.minical').on('keydown.minical', '.day_wrapper', function (ev) {
    const isArrowKey = ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(ev.key)
    const isActivationKey = ev.key === 'Enter' || ev.key === ' '

    if (isArrowKey) {
      ev.preventDefault()
      navigateMiniCalendarDays(ev.key, $(this), $mini_month)
    } else if (isActivationKey) {
      ev.preventDefault()
      $(this).trigger('click')
    }
  })
}

// Announce a date to screen readers by forcing focus re-read
//    Temporarily blurs and refocuses the element to trigger screen reader announcement.
function announceDate($wrapper) {
  if (!$wrapper || !$wrapper.length) return

  $wrapper.blur()
  setTimeout(() => $wrapper.focus(), 50)
}

// Binds to mini calendar dom events
//    Called to bind behaviors to the mini calendar after it's rendered.
//    Sets up day selection, month navigation, and accessibility features.
function bindToMiniCalendar() {
  const $mini_month = $('.mini_month')

  setupMiniCalendarAccessibility($mini_month)

  // Fix button labels for accessibility
  $mini_month.find('.prev_month_link').attr('aria-label', 'Previous month')
  $mini_month.find('.next_month_link').attr('aria-label', 'Next month')

  // Month navigation
  const prev_next_links = $mini_month.find('.next_month_link, .prev_month_link')
  prev_next_links.on('click', function (ev) {
    ev.preventDefault()

    // Store the focused element's position before month change
    const $focusedWrapper = $mini_month.find('.day_wrapper:focus')
    let focusPosition = null

    if ($focusedWrapper.length) {
      const $allWrappers = $mini_month.find('.mini_calendar_day .day_wrapper[tabindex="0"]')
      focusPosition = $allWrappers.index($focusedWrapper)

      // Only store if we found a valid position
      if (focusPosition === -1) {
        focusPosition = null
      }
    }

    changeMonth($mini_month, $(this).hasClass('next_month_link') ? 1 : -1)
    highlightDaysWithEvents()
    setupMiniCalendarAccessibility($mini_month)

    // Restore focus to the same position and announce the new date
    if (focusPosition !== null && focusPosition >= 0) {
      setTimeout(() => {
        const $allWrappers = $mini_month.find('.mini_calendar_day .day_wrapper[tabindex="0"]')
        const $targetWrapper = $allWrappers.eq(focusPosition)

        if ($targetWrapper.length) {
          announceDate($targetWrapper)
        }
      }, 100)
    }
  })

  prev_next_links.on('keydown', function (ev) {
    if (ev.key === ' ' || ev.key === 'Enter') {
      ev.preventDefault()
      $(this).click()
    }
  })

  // Day selection
  const miniCalendarDayClick = function (ev) {
    ev.preventDefault()

    // Store the clicked element's position before month/date change
    const $clickedWrapper = $(ev.target).closest('.day_wrapper')
    const $allWrappers = $mini_month.find('.mini_calendar_day .day_wrapper[tabindex="0"]')
    const focusPosition = $allWrappers.index($clickedWrapper)

    const date = $(ev.target).closest('.mini_calendar_day')[0].id.slice(9)
    const [year, month, day] = Array.from(date.split('_'))
    changeMonth($mini_month, `${month}/${day}/${year}`)
    highlightDaysWithEvents()
    setupMiniCalendarAccessibility($mini_month)
    selectDate(date)

    // Restore focus to the same position and announce the new date
    if (focusPosition >= 0) {
      setTimeout(() => {
        const $allWrappers = $mini_month.find('.mini_calendar_day .day_wrapper[tabindex="0"]')
        const $targetWrapper = $allWrappers.eq(focusPosition)

        if ($targetWrapper.length) {
          announceDate($targetWrapper)
        }
      }, 100)
    }

    const eventSelector = escape(`.events_${date}`)
    $(eventSelector).ifExists($events => setTimeout(() => selectRow($events), 0))
  }

  $mini_month.on('click', '.day_wrapper', miniCalendarDayClick)

  $mini_month.on('focus blur mouseover mouseout', '.day_wrapper', ev => {
    let date
    if (ev.type !== 'mouseout' && ev.type !== 'blur') {
      date = $(ev.target).closest('.mini_calendar_day')[0].id.slice(9)
    }
    highlightDate(date)
  })

  // Jump to today
  $('.jump_to_today_link').on('click', ev => {
    ev.preventDefault()
    const todayString = $.datepicker.formatDate('yy_mm_dd', new Date())
    let $lastBefore
    $('tr.date').each(function () {
      const dateString = $(this).find('.day_date').attr('data-date')

      if (dateString) {
        if (dateString > todayString) {
          if (!$lastBefore) $lastBefore = dateString
          return false
        }
        $lastBefore = dateString
      }
    })

    changeMonth($mini_month, $.datepicker.formatDate('mm/dd/yy', new Date()))
    highlightDaysWithEvents()

    selectDate(todayString)

    const rowToSelect = $lastBefore ? `tr.date.events_${$lastBefore}` : 'tr.syllabus_assignment'
    selectRow($(htmlEscape(rowToSelect)))
  })
}

// Binds to edit syllabus dom events
const bindToEditSyllabus = function (course_summary_enabled) {
  const $course_syllabus = $('#course_syllabus')
  $course_syllabus.data('syllabus_body', ENV.SYLLABUS_BODY)
  const $edit_syllabus_link = $('.edit_syllabus_link')

  // if there's no edit link, don't need to (and shouldn't) do the rest of
  // this. the edit link is included on the page if and only if the user has
  // :manage_course_content_edit permission on the course (see assignments'
  // syllabus_right_side view)
  if (!$edit_syllabus_link.length) return

  function resetToggleLinks() {
    $('.toggle_html_editor_link').show()
    $('.toggle_rich_editor_link').hide()
  }

  const $edit_course_syllabus_form = $('#edit_course_syllabus_form')
  let $course_syllabus_body = $('#course_syllabus_body')
  const $course_syllabus_details = $('#course_syllabus_details')

  $edit_course_syllabus_form.on('edit', () => {
    $edit_course_syllabus_form.show()
    $edit_syllabus_link.hide()
    $edit_syllabus_link.attr('aria-expanded', 'true')
    $course_syllabus.hide()
    $course_syllabus_details.hide()
    easy_student_view.hide()
    $course_syllabus_body = RichContentEditor.freshNode($course_syllabus_body)
    const currentHTML = $course_syllabus.html()
    const originalHTML = $course_syllabus.data('syllabus_body')
    const contentToEdit = currentHTML !== originalHTML ? currentHTML : originalHTML
    $course_syllabus_body.val(contentToEdit)
    RichContentEditor.loadNewEditor($course_syllabus_body, {
      focus: true,
      manageParent: true,
      resourceType: 'syllabus.body',
    })

    $('.jump_to_today_link').focus()
  }) // a11y: Set focus so it doesn't get lost.

  function recreateCourseSyllabusBody() {
    $('#tinymce-parent-of-course_syllabus_body').append($course_syllabus_body)
  }

  $edit_course_syllabus_form.on('hide_edit', () => {
    $edit_course_syllabus_form.hide()
    $edit_syllabus_link.show()
    $edit_syllabus_link.attr('aria-expanded', 'false')
    $course_syllabus.show()
    easy_student_view.show()
    const text = $.trim($course_syllabus.html())
    $course_syllabus_details.showIf(!text)
    RichContentEditor.destroyRCE($course_syllabus_body)
    recreateCourseSyllabusBody()
    resetToggleLinks()
    $edit_syllabus_link.focus()
  })

  $edit_syllabus_link.on('click', ev => {
    ev.preventDefault()
    $edit_course_syllabus_form.triggerHandler('edit')
  })

  $edit_course_syllabus_form.on('click', '.toggle_views_link', ev => {
    ev.preventDefault()
    RichContentEditor.callOnRCE($course_syllabus_body, 'toggle')
    // hide the clicked link, and show the other toggle link.
    // todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(ev.currentTarget).siblings('.toggle_views_link').andSelf().toggle().focus()
  })

  $edit_course_syllabus_form.on('click', '.cancel_button', ev => {
    ev.preventDefault()
    RichContentEditor.closeRCE($course_syllabus_body)
    $edit_course_syllabus_form.triggerHandler('hide_edit')
  })

  return $edit_course_syllabus_form.formSubmit({
    object_name: 'course',

    processData(data) {
      RichContentEditor.closeRCE($course_syllabus_body) // I'd like to wait until success, but by then the RCE is gone
      const syllabus_body = RichContentEditor.callOnRCE($course_syllabus_body, 'get_code')
      data['course[syllabus_body]'] = syllabus_body
      return data
    },

    beforeSubmit(_data) {
      $edit_course_syllabus_form.triggerHandler('hide_edit')
      $course_syllabus_details.hide()
      $course_syllabus.loadingImage()
    },

    success(data) {
      if (data.course.settings.syllabus_course_summary !== course_summary_enabled) {
        return window.location.reload()
      }
      /*
      xsslint safeString.property syllabus_body
      */
      // removing the 'enhanced' class allows any math in the syllabus to re-render on save
      $course_syllabus.removeClass('enhanced')
      $course_syllabus.loadingImage('remove').html(data.course.syllabus_body)
      $course_syllabus.data('syllabus_body', data.course.syllabus_body)
      $course_syllabus_details.hide()
    },

    error(data) {
      return $edit_course_syllabus_form.triggerHandler('edit').formErrors(data)
    },
  })
}

export default {
  bindToEditSyllabus,
  bindToMiniCalendar,
  bindToSyllabus,
}
