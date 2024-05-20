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
import '@canvas/datetime/jquery' // dateString, datepicker
import '@canvas/jquery/jquery.instructure_forms' // formSubmit, formErrors
import '@canvas/jquery/jquery.instructure_misc_plugins' // ifExists, showIf
import '@canvas/loading-image'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jqueryui/datepicker'
import easy_student_view from '@canvas/easy-student-view'
import htmlEscape from '@instructure/html-escape'
import {escape} from 'lodash'

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

// Binds to mini calendar dom events
function bindToMiniCalendar() {
  const $mini_month = $('.mini_month')

  const prev_next_links = $mini_month.find('.next_month_link, .prev_month_link')
  prev_next_links.on('click', function (ev) {
    ev.preventDefault()
    changeMonth($mini_month, $(this).hasClass('next_month_link') ? 1 : -1)
    highlightDaysWithEvents()
  })

  const miniCalendarDayClick = function (ev) {
    ev.preventDefault()
    const date = $(ev.target).closest('.mini_calendar_day')[0].id.slice(9)
    const [year, month, day] = Array.from(date.split('_'))
    changeMonth($mini_month, `${month}/${day}/${year}`)
    highlightDaysWithEvents()
    selectDate(date)
    const eventSelector = escape(`.events_${date}`)
    $(eventSelector).ifExists($events => setTimeout(() => selectRow($events), 0)) // focus race condition hack. why do you do this to me, IE?
  }

  $mini_month.on('keypress', '.day_wrapper', ev => {
    if (ev.which === 13 || ev.which === 32) miniCalendarDayClick(ev)
  })

  $mini_month.on('click', '.day_wrapper', miniCalendarDayClick)

  $mini_month.on('focus blur mouseover mouseout', '.day_wrapper', ev => {
    let date
    if (ev.type !== 'mouseout' && ev.type !== 'blur') {
      date = $(ev.target).closest('.mini_calendar_day')[0].id.slice(9)
    }
    highlightDate(date)
  })

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
  // :manage_content permission on the course (see assignments'
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
    $course_syllabus_body.val($course_syllabus.data('syllabus_body'))
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
