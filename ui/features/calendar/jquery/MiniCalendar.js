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
import {defaults} from 'lodash'
import calendarDefaults from '../CalendarDefaults'
import 'jquery-tinypubsub'

const I18n = createI18nScope('calendar')

export default class MiniCalendar {
  constructor(selector, mainCalendar) {
    this.mainCalendar = mainCalendar
    this.calendar = $(selector)

    this.calendar.fullCalendar(
      defaults(
        {
          height: 185,
          buttonSRText: {
            prev: I18n.t('Previous month'),
            next: I18n.t('Next month'),
          },
          header: {
            left: 'prev',
            center: 'title',
            right: 'next',
          },
          dayClick: this.dayClick,
          events: this.getEvents,
          droppable: true,
          dragRevertDuration: 0,
          dropAccept: '.fc-event,.undated_event',
          drop: this.drop,
          eventDrop: this.drop,
          eventReceive: this.drop,
          viewRender: (view) => {
            this.hideEmptyRows()
            this.hideEmptyCells()
            this.calendar.find('.fc-widget-content td[data-date]').each(function () {
              const $td = $(this)

              // Highlight today
              if ($td.hasClass('fc-today')) {
                $td.css('background-color', '#e0f7fa')
              }

              // Add hover effect over the days
              $td
                .on('mouseenter', () => $td.css('background-color', '#f0f0f0'))
                .on('mouseleave', () => {
                  if ($td.hasClass('fc-today')) {
                    $td.css('background-color', '#e0f7fa')
                  } else {
                    $td.css('background-color', '')
                  }
                })

              // Optional: Add pointer cursor
              $td.css('cursor', 'pointer')
            })

            this.calendar.find('.fc-prev-button').on('click', () => {
              const currentView = this.calendar.fullCalendar('getView')
              const newDate = currentView.intervalStart
              this.mainCalendar.gotoDate(newDate)
            })

            this.calendar.find('.fc-next-button').on('click', () => {
              const currentView = this.calendar.fullCalendar('getView')
              const newDate = currentView.intervalStart
              this.mainCalendar.gotoDate(newDate)
            })
          },
          eventRender: this.eventRender,
        },
        calendarDefaults
      ),
      $.subscribe({
        'Calendar/visibleContextListChanged': this.visibleContextListChanged,
        'Calendar/refetchEvents': this.refetchEvents,
        'Calendar/currentDate': this.gotoDate,
        'CommonEvent/eventDeleted': this.eventSaved,
        'CommonEvent/eventSaved': this.eventSaved,
        'CommonEvent/eventsSavedFromSeries': this.eventsSavedFromSeries,
      })
    )

    // Add ARIA role to calendar container
    this.calendar.attr({
      role: 'region',
      'aria-label': I18n.t('calendar_view', 'Mini calendar view')
    })

    // Label nav buttons
    this.calendar.find('.fc-button').attr('role', 'button')
  }

  hideEmptyRows = () => {
    this.calendar.find('.fc-widget-content tr').each(function () {
      const $row = $(this)

      // Get only visible, non-placeholder <td> cells
      const cells = $row.find('td[data-date]')

      // Check if the row has any event, slot, or visible date
      const hasUsefulContent = cells.toArray().some(td => {
        const $td = $(td)
        return (
          $td.hasClass('event') ||
          $td.hasClass('slot-available') ||
          $td.text().trim() !== ''
        )
      })

      if (!hasUsefulContent) {
        $row.attr('aria-hidden', 'true')
      } else {
        $row.attr('aria-hidden', 'false')
      }
    })
  }

  hideEmptyCells = () => {
    this.calendar.find('.fc-widget-content tr').each(function () {
      const $row = $(this)
      const hasEventOrSlot = $row.find('td.event, td.slot-available').length > 0

      if (hasEventOrSlot) {
        $row.find('td').each(function () {
          const $td = $(this)
          const isEmpty = $td.text().trim() === '' && !$td.hasClass('event') && !$td.hasClass('slot-available')

          if (isEmpty) {
            $td.attr('aria-hidden', 'true')
          } else {
            $td.attr('aria-hidden', 'false')
          }
        })
      }
    })
  }

  getEvents = (start, end, timezone, donecb, datacb) => {
    this.calendar
      .find('.fc-widget-content td')
      .removeClass('event slot-available')
      .removeAttr('title')
      .removeAttr('tabindex')
      .removeAttr('aria-label')
      .off('keydown')

    return this.mainCalendar.getEvents(start, end, timezone, donecb, datacb)
  }

  dayClick = date => {
    this.mainCalendar.gotoDate(date)
  }

  gotoDate = date => {
    this.calendar.fullCalendar('gotoDate', date)
  }

  eventRender = (event, element, view) => {
    const evDate = event.start.format('YYYY-MM-DD')
    const td = view.el.find(`td[data-date="${evDate}"]`)[0]
    if (!td) return false

    const $td = $(td)

    // Skip cells from other months
    if ($td.hasClass('fc-other-month')) return false

    $td.addClass('event')

    let tooltip = I18n.t('event_on_this_day', 'There is an event on this day')

    const appointmentGroupBeingViewed =
      this.mainCalendar.displayAppointmentEvents &&
      this.mainCalendar.displayAppointmentEvents.id

    if (
      appointmentGroupBeingViewed &&
      appointmentGroupBeingViewed ===
      (event.calendarEvent && event.calendarEvent.appointment_group_id) &&
      event.object.available_slots
    ) {
      $td.addClass('slot-available')
      tooltip = I18n.t('open_appointment_on_this_day', 'There is an open appointment on this day')
    }

    // Add accessibility and interaction
    $td
      .attr('title', tooltip)
      .attr('tabindex', 0)
      .attr('role', 'button')
      .attr('aria-label', tooltip)
      .off('keydown.fc-a11y') // prevent multiple bindings
      .on('keydown.fc-a11y', e => {
        switch (e.key) {
          case 'Enter':
          case ' ':
            e.preventDefault()
            this.dayClick(event.start)
            break
          case 'ArrowLeft':
            e.preventDefault()
            this.moveFocus($td, 'left')
            break
          case 'ArrowRight':
            e.preventDefault()
            this.moveFocus($td, 'right')
            break
          case 'ArrowUp':
            e.preventDefault()
            this.moveFocus($td, 'up')
            break
          case 'ArrowDown':
            e.preventDefault()
            this.moveFocus($td, 'down')
            break
        }
      })
      .off('click.fc-a11y')
      .on('click.fc-a11y', () => {
        this.dayClick(event.start)
      })

    return false
  }

  moveFocus = ($currentCell, direction) => {
    const $rows = this.calendar.find('.fc-widget-content tr')
    let currentRowIndex = -1
    let currentColIndex = -1

    // Find current cell's row and column
    $rows.each(function (rowIdx) {
      const $cells = $(this).find('td')
      $cells.each(function (colIdx) {
        if (this === $currentCell[0]) {
          currentRowIndex = rowIdx
          currentColIndex = colIdx
        }
      })
    })

    if (currentRowIndex === -1 || currentColIndex === -1) return

    let newRowIndex = currentRowIndex
    let newColIndex = currentColIndex

    const maxRowIndex = $rows.length - 1
    const maxColIndex = 6 // 7 columns (0–6)

    switch (direction) {
      case 'left':
        if (newColIndex > 0) {
          newColIndex--
        } else if (newRowIndex > 0) {
          newRowIndex--
          newColIndex = maxColIndex
        } else {
          // wrap to last cell
          newRowIndex = maxRowIndex
          newColIndex = maxColIndex
        }
        break

      case 'right':
        if (newColIndex < maxColIndex) {
          newColIndex++
        } else if (newRowIndex < maxRowIndex) {
          newRowIndex++
          newColIndex = 0
        } else {
          // wrap to first cell
          newRowIndex = 0
          newColIndex = 0
        }
        break

      case 'up':
        if (newRowIndex > 0) newRowIndex--
        break

      case 'down':
        if (newRowIndex < maxRowIndex) newRowIndex++
        break
    }

    // Focus the new cell if it's tabbable
    const $targetRow = $rows.eq(newRowIndex)
    const $targetCell = $targetRow.find('td').eq(newColIndex)

    if ($targetCell.length && $targetCell.is('[tabindex="0"]')) {
      $targetCell.focus()
    } else {
      // Optionally search nearby if target isn't focusable
      const $fallback = $targetRow.find('td[tabindex="0"]').first()
      if ($fallback.length) $fallback.focus()
    }
  }

  visibleContextListChanged = _list => this.refetchEvents()

  eventSaved = () => this.refetchEvents()

  eventsSavedFromSeries = () => this.refetchEvents()

  refetchEvents = () => {
    if (!this.calendar.is(':visible')) return
    return this.calendar.fullCalendar('refetchEvents')
  }

  drop = (date, jsEvent, ui, view) => {
    const allDay = view.options.allDayDefault
    if (ui.helper.is('.undated_event')) {
      return this.mainCalendar.drop(date, allDay, jsEvent, ui)
    } else if (ui.helper.is('.fc-event')) {
      return this.mainCalendar.dropOnMiniCalendar(date, allDay, jsEvent, ui)
    }
  }
}

