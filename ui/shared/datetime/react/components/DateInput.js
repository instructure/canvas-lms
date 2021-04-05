/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!app_shared_components_canvas_date_time'
import React, {useRef, useState} from 'react'
import {arrayOf, bool, element, func, oneOfType, shape, string} from 'prop-types'
import moment from 'moment-timezone'
import tz from '@canvas/timezone'
import {DateTime} from '@instructure/ui-i18n'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Calendar} from '@instructure/ui-calendar'
import {DateInput} from '@instructure/ui-date-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndSolid, IconArrowOpenStartSolid} from '@instructure/ui-icons'

/*
 *   This is a helper component that interfaces with InstUI 7's DateInput.
 *   DateInput is highly unopinionated and throws a lot of formatting and
 *   event handling over the fence to the caller, some of which can get rather
 *   involved. So we deal with much of it here.
 *
 * props:
 *   selectedDate  [string]
 *      Represents the initial date to be selected. May be null for no selected date.
 *
 *   renderLabel  [DOMElement|string|function]
 *      Passed along to DateInput, specifies the input label.
 *
 *   messages  [array of objects {type: string, text: string}]
 *      Passed along to DateInput, can be used to describe messages and validation
 *      for the input. Note that this component may display its own messages as well.
 *
 *   timezone  [string]
 *      Specifies the time zone that the DateInput picker is operating in. Defaults
 *      to either ENV.TIMEZONE if present, or the browser's timezone otherwise. It also
 *      depends on moment.js's default locale being set (always the case in Canvas).
 *
 *   formatDate  [function]
 *      A function which is called to format the date into DateTime's text box
 *      when it is selected. There is no default (this must be provided), but it's
 *      usually sufficient to provide something like this:
 *            date => tz.format(date, 'date.formats.medium_with_weekday')
 *
 *   onSelectedDateChange  [function]
 *      A callback function which is called when a date has been selected, either by
 *      typing it in and tabbing out of the field, or by clicking on a date in the
 *      calendar. It is called with one argument, a JS Date object. If the input is
 *      a bad date (such as if the user types something unparseable) the value passed
 *      will evaluate to Boolean `false`
 *
 *   interaction  [string: "enabled" | "disabled" | "readonly"]
 *      Passed along to DateInput. Specifies if interaction with the input is enabled,
 *      disabled, or read-only. Read-only prevents interactions, but is styled as if
 *      it were enabled.
 *
 *   withRunningValue  [boolean]
 *      Controls whether or not a message continually appears at the bottom of the field
 *      showing what date WOULD be selected right now. It's to help the user out when they
 *      type something possibly ambiguous like "5/4/19". As an additional feature of that
 *      functionality, the calendar display is hidden during typing so that it doesn't
 *      block that message area. Specifying this prop can highlight the dual functionality
 *      of picking a date from the popup calendar vs typing a date in by hand.
 *
 *   invalidDateMessage  [string | function]
 *      Specifies the error message shown under the input when it contains an invalid date.
 *      Defaults to just "Invalid date".
 *
 *   layout  [string: "stacked" | "inline"]
 *      Passed along to DateInput. Controls whether the label is stacked on top of the input
 *      or placed next to the input.
 *
 *   width  [string]
 *      Passed along to DateInput. Controls width of the input. Defaults to null, which leaves
 *      width setting up to size prop.
 */

CanvasDateInput.propTypes = {
  selectedDate: string,
  renderLabel: oneOfType([element, string, func]),
  messages: arrayOf(shape({type: string, text: string})),
  timezone: string,
  formatDate: func.isRequired,
  onSelectedDateChange: func.isRequired,
  interaction: string,
  placement: string,
  withRunningValue: bool,
  invalidDateMessage: oneOfType([string, func]),
  layout: string,
  width: string
}

CanvasDateInput.defaultProps = {
  selectedDate: null,
  timezone: ENV?.TIMEZONE || DateTime.browserTimeZone(),
  renderLabel: I18n.t('Choose a date'),
  messages: [],
  interaction: 'enabled',
  placement: 'bottom center',
  withRunningValue: false,
  layout: 'stacked',
  width: null
}

export default function CanvasDateInput({
  selectedDate,
  renderLabel,
  messages,
  timezone,
  formatDate,
  onSelectedDateChange,
  interaction,
  placement,
  withRunningValue,
  invalidDateMessage,
  layout,
  width
}) {
  const todayMoment = moment().tz(timezone)
  const selectedMoment = selectedDate && moment.tz(selectedDate, timezone)

  const [inputValue, setInputValue] = useState('')
  const [isShowingCalendar, setIsShowingCalendar] = useState(false)
  const [renderedMoment, setRenderedMoment] = useState(selectedMoment || todayMoment)
  const [internalMessages, setInternalMessages] = useState([])

  const priorSelectedMoment = useRef(null)
  function isDifferentMoment(firstMoment, secondMoment) {
    const changedNull =
      (firstMoment === null && secondMoment !== null) ||
      (firstMoment !== null && secondMoment == null)
    const changedValue = firstMoment && firstMoment.isValid() && !firstMoment.isSame(secondMoment)
    return changedNull || changedValue
  }

  if (isDifferentMoment(selectedMoment, priorSelectedMoment.current)) {
    syncInput(selectedMoment)
  }
  // now that we've done the check, we can update this value
  priorSelectedMoment.current = selectedMoment

  function syncInput(newMoment) {
    const newInputValue = newMoment && newMoment.isValid() ? formatDate(newMoment.toDate()) : ''
    setInputValue(newInputValue)
    setInternalMessages([])
    setRenderedMoment(newMoment || todayMoment)
  }

  function generateMonthMoments() {
    const firstMoment = moment.tz(renderedMoment, timezone).startOf('month').startOf('week')
    return [...Array(Calendar.DAY_COUNT).keys()].map(index =>
      firstMoment.clone().add(index, 'days')
    )
  }

  function renderDays() {
    // This is expensive, so only do it if the calendar is open
    if (!isShowingCalendar) return null
    const days = generateMonthMoments().map(dayMoment => (
      <DateInput.Day
        key={dayMoment.toISOString()}
        date={dayMoment.toISOString(true)}
        label={tz.format(dayMoment.toDate(), 'date.formats.medium')}
        isSelected={dayMoment.isSame(selectedMoment, 'day')}
        isToday={dayMoment.isSame(todayMoment, 'day')}
        isOutsideMonth={!dayMoment.isSame(renderedMoment, 'month')}
        onClick={handleDayClick}
      >
        {dayMoment.format('D')}
      </DateInput.Day>
    ))
    return days
  }

  function invalidText(text) {
    if (typeof invalidDateMessage === 'function') return invalidDateMessage(text)
    if (typeof invalidDateMessage === 'undefined') return I18n.t('Invalid Date')
    return invalidDateMessage
  }

  function handleChange(_event, {value}) {
    setInputValue(value)
    // If we have been asked to show the running value, hide the popup
    if (isShowingCalendar && withRunningValue) handleHideCalendar()
    const newDate = tz.parse(value)
    if (newDate) {
      const msgs = withRunningValue ? [{type: 'success', text: formatDate(newDate)}] : []
      setRenderedMoment(moment.tz(newDate, timezone))
      setInternalMessages(msgs)
    } else if (value === '') {
      setInternalMessages([])
    } else {
      const text = invalidText(value)
      setInternalMessages([{type: 'error', text}])
    }
  }

  function handleDayClick(_event, {date}) {
    const parsedMoment = moment.tz(date, timezone)
    syncInput(parsedMoment)
    onSelectedDateChange(parsedMoment.toDate())
  }

  function handleBlur() {
    const newDate = tz.parse(inputValue)
    syncInput(newDate ? moment.tz(newDate, timezone) : null)
    onSelectedDateChange(newDate)
    if (!newDate) syncInput(priorSelectedMoment.current)
  }

  function handleHideCalendar() {
    setIsShowingCalendar(false)
  }

  function handleShowCalendar({nativeEvent: e}) {
    // Do not re-show the calendar if input was typing and we have been asked to
    // show the running value. For some reason DateInput reflects an InputEvent for
    // all typing EXCEPT for spaces, which come in as KeyboardEvents, so we have to
    // deal with both. 🤷🏼‍♂️
    if (withRunningValue) {
      if (e.constructor.name === 'InputEvent') return
      if (e.key === ' ') {
        setInputValue(v => v + ' ')
        return
      }
    }
    setIsShowingCalendar(true)
  }

  function modifySelectedMoment(step, type) {
    // If we do not have a selectedMoment, we'll just select the first day of
    // the currently rendered month.
    const newMoment = selectedMoment
      ? selectedMoment.clone().add(step, type).startOf('day')
      : renderedMoment.clone().startOf('month')

    onSelectedDateChange(newMoment.toDate())
  }

  function modifyRenderedMoment(step, type) {
    setRenderedMoment(renderedMoment.clone().add(step, type).startOf('day'))
  }

  function renderWeekdayLabels() {
    // This is expensive, so only do it if the calendar is open
    if (!isShowingCalendar) return []

    const firstOfWeek = renderedMoment.clone().startOf('week')
    return [...Array(7).keys()].map(index => {
      const thisDay = firstOfWeek.clone().add(index, 'days')
      return (
        <AccessibleContent alt={thisDay.format('dddd')}>{thisDay.format('dd')}</AccessibleContent>
      )
    })
  }

  function renderMonthChangeButton(direction) {
    if (!isShowingCalendar) return null

    const icon =
      direction === 'prev' ? (
        <IconArrowOpenStartSolid color="primary" />
      ) : (
        <IconArrowOpenEndSolid color="primary" />
      )
    const label = direction === 'prev' ? I18n.t('Previous month') : I18n.t('Next month')
    return (
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        renderIcon={icon}
        screenReaderLabel={label}
      />
    )
  }

  return (
    <DateInput
      renderLabel={renderLabel}
      assistiveText={I18n.t('Type a date or use arrow keys to navigate date picker.')}
      value={inputValue}
      onChange={handleChange}
      isInline
      placement={placement}
      messages={messages.concat(internalMessages)}
      isShowingCalendar={isShowingCalendar}
      onBlur={handleBlur}
      onRequestShowCalendar={handleShowCalendar}
      onRequestHideCalendar={handleHideCalendar}
      onRequestSelectNextDay={() => modifySelectedMoment(1, 'day')}
      onRequestSelectPrevDay={() => modifySelectedMoment(-1, 'day')}
      onRequestRenderNextMonth={() => modifyRenderedMoment(1, 'month')}
      onRequestRenderPrevMonth={() => modifyRenderedMoment(-1, 'month')}
      renderNavigationLabel={
        <span>
          <div>{renderedMoment.format('MMMM')}</div>
          <div>{renderedMoment.format('YYYY')}</div>
        </span>
      }
      renderPrevMonthButton={renderMonthChangeButton('prev')}
      renderNextMonthButton={renderMonthChangeButton('next')}
      renderWeekdayLabels={renderWeekdayLabels()}
      interaction={interaction}
      layout={layout}
      width={width}
    >
      {renderDays()}
    </DateInput>
  )
}
