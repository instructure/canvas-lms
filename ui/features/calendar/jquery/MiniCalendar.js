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

// Constants for styling
const TODAY_BACKGROUND_COLOR = '#e0f7fa'
const HOVER_BACKGROUND_COLOR = '#f0f0f0'

export default class MiniCalendar {
  constructor(selector, mainCalendar) {
    this.mainCalendar = mainCalendar
    this.calendar = $(selector)
    this.focusPositionAfterRender = null
    this.initializeCalendar()
    this.setupAccessibility()
  }

  /**
   * Initialize the FullCalendar instance with configuration
   */
  initializeCalendar() {
    const calendarConfig = {
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
      viewRender: this.handleViewRender,
      eventRender: this.eventRender,
    }

    const subscriptions = {
      'Calendar/visibleContextListChanged': this.visibleContextListChanged,
      'Calendar/refetchEvents': this.refetchEvents,
      'Calendar/currentDate': this.gotoDate,
      'CommonEvent/eventDeleted': this.eventSaved,
      'CommonEvent/eventSaved': this.eventSaved,
      'CommonEvent/eventsSavedFromSeries': this.eventsSavedFromSeries,
    }

    this.calendar.fullCalendar(
      defaults(calendarConfig, calendarDefaults),
      $.subscribe(subscriptions),
    )
  }

  /**
   * Set up accessibility features for the calendar
   */
  setupAccessibility() {
    this.calendar.attr({
      role: 'region',
      'aria-label': I18n.t('calendar_view', 'Mini calendar view'),
    })

    this.calendar.find('.fc-button').attr('role', 'button')
    this.createLiveRegion()
  }

  /**
   * Create a live region for screen reader announcements
   */
  createLiveRegion() {
    if ($('#minical-live-region').length === 0) {
      $(
        '<div id="minical-live-region" aria-live="polite" aria-atomic="true" class="screenreader-only"></div>',
      ).appendTo('body')
    }
  }

  /**
   * Handle the viewRender callback from FullCalendar
   * Called whenever the calendar view changes (month navigation)
   */
  handleViewRender = _view => {
    this.hideEmptyRows()
    this.hideEmptyCells()
    this.setupAccessibleDays()
    this.setupDayInteractions()
    this.setupNavigationButtons()

    // Restore focus to same position if navigating via prev/next buttons
    if (this.focusPositionAfterRender !== null) {
      this.restoreFocusToPosition(this.focusPositionAfterRender)
      this.focusPositionAfterRender = null
    }
  }

  /**
   * Add visual styling and hover effects to day cells
   */
  setupDayInteractions() {
    this.calendar.find('.fc-widget-content td[data-date]').each(function () {
      const $td = $(this)

      if ($td.hasClass('fc-today')) {
        $td.css('background-color', TODAY_BACKGROUND_COLOR)
      }

      $td
        .css('cursor', 'pointer')
        .on('mouseenter', () => $td.css('background-color', HOVER_BACKGROUND_COLOR))
        .on('mouseleave', () => {
          const bgColor = $td.hasClass('fc-today') ? TODAY_BACKGROUND_COLOR : ''
          $td.css('background-color', bgColor)
        })
    })
  }

  /**
   * Set up prev/next navigation buttons to sync with main calendar
   * Ensures keyboard accessibility with Space and Enter keys
   */
  setupNavigationButtons() {
    const setupButton = (selector, className, ariaLabel) => {
      const $button = this.calendar.find(selector)

      // Store reference for consistent naming and set proper aria-label
      if (className) {
        $button.addClass(className)
      }

      // Set aria-label to match Syllabus calendar
      $button.attr('aria-label', ariaLabel)

      $button.off('click.minical-sync').on('click.minical-sync', () => {
        // Store the focused element's position before month change
        const $focusedButton = this.calendar.find('.day-wrapper-button:focus')

        if ($focusedButton.length) {
          const $allButtons = this.calendar.find(
            '.fc-content-skeleton .day-wrapper-button[tabindex="0"]',
          )
          this.focusPositionAfterRender = $allButtons.index($focusedButton)
        }

        setTimeout(() => {
          const currentView = this.calendar.fullCalendar('getView')
          this.mainCalendar.gotoDate(currentView.intervalStart)
        }, 0)
      })

      $button.off('keydown.minical').on('keydown.minical', e => {
        if (e.key === ' ' || e.key === 'Enter') {
          e.preventDefault()
          $button.click()
        }
      })
    }

    setupButton('.fc-prev-button', 'prev_month_link', I18n.t('Previous month'))
    setupButton('.fc-next-button', 'next_month_link', I18n.t('Next month'))
  }

  /**
   * Set up keyboard accessibility for all calendar days
   * Makes all visible days navigable via keyboard and screen readers
   */
  setupAccessibleDays = () => {
    this.removeTableSemantics()
    const currentMonth = this.getCurrentMonth()
    const dayCells = this.calendar.find('.fc-content-skeleton td.fc-day-top[data-date]')

    dayCells.each((_index, cell) => {
      this.setupAccessibleDay($(cell), currentMonth)
    })
  }

  /**
   * Remove table semantics from calendar structure
   * Prevents screen readers from announcing table navigation
   */
  removeTableSemantics() {
    const selectors = [
      '.fc-view-container table',
      '.fc-view-container thead',
      '.fc-view-container tbody',
      '.fc-view-container tr',
      '.fc-view-container th',
      '.fc-view-container td',
    ]

    selectors.forEach(selector => {
      this.calendar.find(selector).attr('role', 'presentation')
    })

    this.calendar.find('.fc-bg td[data-date]').attr('tabindex', '-1')
  }

  /**
   * Get the current month from the calendar view
   * Returns zero-based month index (0 = January, 11 = December)
   */
  getCurrentMonth() {
    const currentView = this.calendar.fullCalendar('getView')
    return currentView.intervalStart.month()
  }

  /**
   * Set up keyboard accessibility for a single day cell
   * Creates accessible button with proper ARIA labels and keyboard navigation
   */
  setupAccessibleDay($td, currentMonth) {
    const dateStr = $td.data('date')
    if (!dateStr) return

    const momentDate = $.fullCalendar.moment(dateStr)
    const ariaLabel = this.buildDayAriaLabel($td, momentDate, currentMonth)
    const $button = this.getOrCreateDayButton($td)

    this.configureDayButton($button, ariaLabel, momentDate)
  }

  /**
   * Build comprehensive ARIA label for a day cell
   * Includes weekday, date, and contextual information
   */
  buildDayAriaLabel($td, momentDate, currentMonth) {
    const date = momentDate.toDate()
    const weekday = date.toLocaleDateString(undefined, {weekday: 'long'})
    const monthName = date.toLocaleDateString(undefined, {month: 'long'})
    const dayNum = date.getDate()
    const year = date.getFullYear()

    let label = `${weekday}, ${monthName} ${dayNum}, ${year}`

    if ($td.hasClass('fc-today')) {
      label += ', Today'
    }

    if ($td.hasClass('fc-other-month')) {
      const isPrevMonth = momentDate.month() < currentMonth
      label += isPrevMonth ? ', Previous month' : ', Next month'
    }

    if ($td.hasClass('event') || $td.hasClass('slot-available')) {
      label += ', Has events'
    }

    return label
  }

  /**
   * Get existing day button or create new one
   * Returns the button element used for keyboard interaction
   */
  getOrCreateDayButton($td) {
    let $button = $td.find('.day-wrapper-button')

    if ($button.length === 0) {
      const dayText = $td.find('.fc-day-number').text()
      $button = this.createDayButton(dayText)
      // Keep existing content structure but make it a button
      $td.find('.fc-day-number').replaceWith($button)
    }

    return $button
  }

  /**
   * Create a new day button element
   * Returns styled button with transparent background to inherit cell styling
   * Keeps fc-day-number class for backwards compatibility with tests
   */
  createDayButton(dayText) {
    return $('<button class="day-wrapper-button fc-day-number"></button>').text(dayText).css({
      border: 'none',
      background: 'transparent',
      padding: '0',
      margin: '0',
      font: 'inherit',
      color: 'inherit',
      opacity: 'inherit',
      cursor: 'pointer',
      width: '100%',
      height: '100%',
      textAlign: 'inherit',
      display: 'inline-block',
      lineHeight: 'inherit',
      verticalAlign: 'baseline',
    })
  }

  /**
   * Configure day button with accessibility attributes and event handlers
   * Sets up ARIA labels, keyboard navigation, and click handling
   */
  configureDayButton($button, ariaLabel, momentDate) {
    $button
      .attr({
        tabindex: '0',
        'aria-label': ariaLabel,
        title: ariaLabel,
      })
      .data('aria-label', ariaLabel)
      .off('click.minical keydown.minical')
      .on('click.minical', () => {
        // Store position before clicking day
        const $allButtons = this.calendar.find(
          '.fc-content-skeleton .day-wrapper-button[tabindex="0"]',
        )
        this.focusPositionAfterRender = $allButtons.index($button)

        this.dayClick(momentDate)
      })
      .on('keydown.minical', e => this.handleDayKeydown(e, $button, momentDate))
  }

  /**
   * Handle keydown events on day buttons
   * Supports Enter/Space for activation and arrow keys for navigation
   */
  handleDayKeydown(event, $button, momentDate) {
    const {key} = event

    if (key === 'Enter' || key === ' ') {
      event.preventDefault()

      // Store position before activating day
      const $allButtons = this.calendar.find(
        '.fc-content-skeleton .day-wrapper-button[tabindex="0"]',
      )
      this.focusPositionAfterRender = $allButtons.index($button)

      this.dayClick(momentDate)
    } else if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(key)) {
      event.preventDefault()
      this.navigateDays(key, $button)
    }
  }

  /**
   * Navigate between day buttons using arrow keys
   * Handles wrapping at calendar boundaries for seamless navigation
   */
  navigateDays = (key, $currentButton) => {
    const $allButtons = this.calendar.find('.fc-content-skeleton .day-wrapper-button[tabindex="0"]')
    const currentIndex = $allButtons.index($currentButton)

    if (currentIndex === -1) return

    const targetIndex = this.calculateNavigationTarget(key, currentIndex, $allButtons.length)
    $allButtons.eq(targetIndex).focus()
  }

  /**
   * Calculate target button index for arrow key navigation
   * Returns new index with boundary wrapping
   */
  calculateNavigationTarget(key, currentIndex, totalButtons) {
    const DAYS_PER_WEEK = 7

    switch (key) {
      case 'ArrowLeft':
        return this.wrapIndex(currentIndex - 1, totalButtons)

      case 'ArrowRight':
        return this.wrapIndex(currentIndex + 1, totalButtons)

      case 'ArrowUp':
        return this.navigateVertical(currentIndex, -DAYS_PER_WEEK, totalButtons)

      case 'ArrowDown':
        return this.navigateVertical(currentIndex, DAYS_PER_WEEK, totalButtons)

      default:
        return currentIndex
    }
  }

  /**
   * Wrap index for circular navigation
   */
  wrapIndex(index, total) {
    if (index < 0) return total - 1
    if (index >= total) return 0
    return index
  }

  /**
   * Calculate target index for vertical navigation (up/down arrows)
   * Maintains column position when wrapping to different rows
   */
  navigateVertical(currentIndex, offset, totalButtons) {
    const DAYS_PER_WEEK = 7
    let targetIndex = currentIndex + offset

    if (targetIndex < 0) {
      const column = currentIndex % DAYS_PER_WEEK
      const lastRowStart = Math.floor((totalButtons - 1) / DAYS_PER_WEEK) * DAYS_PER_WEEK
      targetIndex = lastRowStart + column
      if (targetIndex >= totalButtons) {
        targetIndex = totalButtons - DAYS_PER_WEEK + column
      }
    } else if (targetIndex >= totalButtons) {
      targetIndex = currentIndex % DAYS_PER_WEEK
    }

    return targetIndex
  }

  /**
   * Hide rows that don't contain any useful content
   */
  hideEmptyRows = () => {
    this.calendar.find('.fc-widget-content tr').each(function () {
      const $row = $(this)
      const cells = $row.find('td[data-date]')

      const hasUsefulContent = cells.toArray().some(td => {
        const $td = $(td)
        return $td.hasClass('event') || $td.hasClass('slot-available') || $td.text().trim() !== ''
      })

      $row.attr('aria-hidden', hasUsefulContent ? 'false' : 'true')
    })
  }

  /**
   * Hide empty cells in rows that contain events
   */
  hideEmptyCells = () => {
    this.calendar.find('.fc-widget-content tr').each(function () {
      const $row = $(this)
      const hasEventOrSlot = $row.find('td.event, td.slot-available').length > 0

      if (hasEventOrSlot) {
        $row.find('td').each(function () {
          const $td = $(this)
          const isEmpty =
            $td.text().trim() === '' && !$td.hasClass('event') && !$td.hasClass('slot-available')

          $td.attr('aria-hidden', isEmpty ? 'true' : 'false')
        })
      }
    })
  }

  /**
   * Get events for the specified date range
   */
  getEvents = (start, end, timezone, donecb, datacb) => {
    this.calendar
      .find('.fc-widget-content td')
      .removeClass('event slot-available')
      .removeAttr('title')
      .removeAttr('aria-label')
      .off('keydown.fc-a11y')

    return this.mainCalendar.getEvents(start, end, timezone, donecb, datacb)
  }

  /**
   * Handle day click - navigate main calendar to selected date
   */
  dayClick = date => {
    this.mainCalendar.gotoDate(date)
  }

  /**
   * Restore focus to the same position (row/column) after month navigation
   * Keeps focus in the same calendar position when navigating months
   * Announces the new date to screen readers
   */
  restoreFocusToPosition(position) {
    setTimeout(() => {
      const $allButtons = this.calendar.find(
        '.fc-content-skeleton .day-wrapper-button[tabindex="0"]',
      )
      const $targetButton = $allButtons.eq(position)

      if ($targetButton.length) {
        this.announceDate($targetButton)
      }
    }, 100)
  }

  /**
   * Announce a date to screen readers by forcing focus re-read
   * Temporarily blurs and refocuses the element to trigger screen reader announcement
   */
  announceDate($button) {
    if (!$button || !$button.length) return

    $button.blur()
    setTimeout(() => $button.focus(), 50)
  }

  /**
   * Navigate mini calendar to a specific date
   */
  gotoDate = date => {
    this.calendar.fullCalendar('gotoDate', date)
  }

  /**
   * Render an event on the mini calendar
   */
  eventRender = (event, _element, view) => {
    const evDate = event.start.format('YYYY-MM-DD')
    const td = view.el.find(`td[data-date="${evDate}"]`)[0]
    if (!td) return false

    const $td = $(td)

    // Skip cells from other months
    if ($td.hasClass('fc-other-month')) return false

    $td.addClass('event')

    // Mark available appointment slots
    const appointmentGroupBeingViewed = this.mainCalendar.displayAppointmentEvents?.id

    const isAvailableSlot =
      appointmentGroupBeingViewed &&
      appointmentGroupBeingViewed === event.calendarEvent?.appointment_group_id &&
      event.object.available_slots

    if (isAvailableSlot) {
      $td.addClass('slot-available')
    }

    // Don't render the event element in mini calendar
    return false
  }

  /**
   * Event subscription handlers
   */
  visibleContextListChanged = _list => this.refetchEvents()

  eventSaved = () => this.refetchEvents()

  eventsSavedFromSeries = () => this.refetchEvents()

  /**
   * Refetch events if calendar is visible
   */
  refetchEvents = () => {
    if (!this.calendar.is(':visible')) return
    return this.calendar.fullCalendar('refetchEvents')
  }

  /**
   * Handle drag and drop events
   */
  drop = (date, jsEvent, ui, view) => {
    const allDay = view.options.allDayDefault

    if (ui.helper.is('.undated_event')) {
      return this.mainCalendar.drop(date, allDay, jsEvent, ui)
    }

    if (ui.helper.is('.fc-event')) {
      return this.mainCalendar.dropOnMiniCalendar(date, allDay, jsEvent, ui)
    }
  }
}
