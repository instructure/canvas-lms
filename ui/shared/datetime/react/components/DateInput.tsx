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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {ReactNode, useRef, useState} from 'react'
import moment, {Moment} from 'moment-timezone'
import tz from '@canvas/timezone'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Calendar} from '@instructure/ui-calendar'
import {DateInput} from '@instructure/ui-date-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndSolid, IconArrowOpenStartSolid} from '@instructure/ui-icons'
import {nanoid} from 'nanoid'
import {log} from '@canvas/datetime-natural-parsing-instrument'
import {
  DateInputInteraction,
  DateInputLayout,
  DateInputDisplay,
  DateInputSize
} from '@instructure/ui-date-input/types'

const I18n = useI18nScope('app_shared_components_canvas_date_time')

// can use INSTUI definition of the message type once
// https://github.com/instructure/instructure-ui/issues/815 is closed
// import {FormPropTypes} from '@instructure/ui-form-field'
// export type CanvasDateInputMessageType = FormPropTypes.message
export type CanvasDateInputMessageType = {
  text: string | JSX.Element
  type: 'error' | 'warning' | 'hint' | 'success' | 'screenreader-only'
}

export type CanvasDateInputProps = {
  /**
   * Represents the initial date to be selected. May be `undefined` for no selected date.
   */
  selectedDate?: string
  /**
   * Passed along to `DateInput`, specifies the input label.
   */
  renderLabel?: ReactNode
  /**
   * Passed along to `DateInput`, can be used to describe messages and validation for the input. Note that this
   * component may display its own messages as well.
   */
  messages?: CanvasDateInputMessageType[]
  /**
   * Specifies the time zone that the `DateInput` picker is operating in. Defaults to either `ENV.TIMEZONE` if present,
   * or the browser's timezone otherwise. It also depends on moment.js's default locale being set (always the case in
   * Canvas).
   */
  timezone?: string
  /**
   * A function which is called to format the date into `DateTime`'s text box when it is selected. There is no default
   * (this must be provided), but it's usually sufficient to provide something like this:
   * `date => tz.format(date, 'date.formats.medium_with_weekday')`
   */
  formatDate: (date: Moment) => string
  /**
   * A callback function which is called when a date has been selected, either by typing it in and tabbing out of the
   * field, or by clicking on a date in the calendar. It is called with one argument, a JS `Date` object. If the input
   * is a bad date (such as if the user types something unparseable) the value passed will evaluate to Boolean `false`.
   */
  onSelectedDateChange: (date: Date | null) => void
  /**
   * focus and blur event handlers
   */
  onBlur?: (event: React.FormEvent<HTMLInputElement>) => void
  onFocus?: (event: React.FormEvent<HTMLInputElement>) => void
  /**
   * Passed along to `DateInput`. Specifies if interaction with the input is enabled, disabled, or read-only. Read-only
   * prevents interactions, but is styled as if it were enabled.
   */
  interaction?: DateInputInteraction
  locale?: string
  placement?: any // passed through to `DateInput`, which accepts `any`
  /**
   * Controls whether or not a message continually appears at the bottom of the field showing what date WOULD be
   * selected right now. It's to help the user out when they type something possibly ambiguous like "5/4/19". As an
   * additional feature of that functionality, the calendar display is hidden during typing so that it doesn't block
   * that message area. Specifying this prop can highlight the dual functionality of picking a date from the popup
   * calendar vs typing a date in by hand.
   */
  withRunningValue?: boolean
  /**
   * Specifies the error message shown under the input when it contains an invalid date. Defaults to just "Invalid Date".
   */
  invalidDateMessage?: string | ((value: string) => string)
  /**
   * Passed along to `DateInput`. Controls whether the label is stacked on top of the input or placed next to the input.
   */
  layout?: DateInputLayout
  /**
   * Passed along to `DateInput`. Controls width of the input. Defaults to `null`, which leaves width setting up to
   * `size` prop.
   */
  width?: string
  /**
   * A function which validates whether or not a date should render with the `disabled` interaction style.
   */
  dateIsDisabled?: (date: Moment) => boolean
  /**
   * data test id for test selection
   */
  dataTestid?: string
  /**
   * Specifies the input size. One of: small medium large
   */
  size?: DateInputSize
  /**
   * Specifies the display property of the container. One of: inline-block block
   */
  display?: DateInputDisplay
}

/**
 * This is a helper component that interfaces with InstUI 7's DateInput. DateInput is highly un-opinionated and throws a
 * lot of formatting and event handling over the fence to the caller, some of which can get rather involved. So we deal
 * with much of it here.
 */
export default function CanvasDateInput({
  selectedDate,
  renderLabel = I18n.t('Choose a date'),
  messages = [],
  timezone = ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone,
  formatDate,
  onSelectedDateChange,
  onBlur,
  onFocus,
  interaction = 'enabled',
  locale: specifiedLocale,
  placement = 'bottom center',
  withRunningValue,
  invalidDateMessage,
  layout = 'stacked',
  width,
  dateIsDisabled,
  dataTestid,
  size,
  display
}: CanvasDateInputProps) {
  const todayMoment = moment().tz(timezone)
  const selectedMoment = selectedDate ? moment.tz(selectedDate, timezone) : null

  const [inputValue, setInputValue] = useState('')
  const [isShowingCalendar, setIsShowingCalendar] = useState(false)
  const [renderedMoment, setRenderedMoment] = useState(selectedMoment || todayMoment)
  const [internalMessages, setInternalMessages] = useState<typeof messages>([])
  const [widgetId] = useState(nanoid())
  const [inputDetails, setInputDetails] = useState<{
    method: 'paste' | 'pick'
    value: string
  } | null>(null)

  const priorSelectedMoment = useRef<Moment | null>(null)
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
    // @ts-ignore DAY_COUNT is not included in instructure-ui 7 types
    return [...Array(Calendar.DAY_COUNT).keys()].map(index =>
      firstMoment.clone().add(index, 'days')
    )
  }

  function renderDays() {
    // This is expensive, so only do it if the calendar is open
    if (!isShowingCalendar) return null

    const locale = specifiedLocale || ENV?.LOCALE || navigator.language

    const labelFormatter = new Intl.DateTimeFormat(locale, {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      timeZone: timezone
    })

    const dayFormat = new Intl.DateTimeFormat(locale, {
      day: 'numeric',
      timeZone: timezone
    })

    return generateMonthMoments().map(dayMoment => (
      <DateInput.Day
        key={dayMoment.toISOString()}
        date={dayMoment.toISOString(true)}
        interaction={dateIsDisabled && dateIsDisabled(dayMoment) ? 'disabled' : 'enabled'}
        label={labelFormatter.format(dayMoment.toDate())}
        isSelected={dayMoment.isSame(selectedMoment, 'day')}
        isToday={dayMoment.isSame(todayMoment, 'day')}
        isOutsideMonth={!dayMoment.isSame(renderedMoment, 'month')}
        onClick={handleDayClick}
      >
        {dayFormat.format(dayMoment.toDate())}
      </DateInput.Day>
    ))
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
    const newDate = tz.parse(value, timezone)
    if (newDate) {
      const msgs: CanvasDateInputMessageType[] = withRunningValue
        ? [{type: 'success', text: formatDate(newDate)}]
        : []
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
    setInputDetails({method: 'pick', value: date})
  }

  function handleBlur(event) {
    const errorsExist = internalMessages.filter(m => m.type === 'error').length > 0
    const inputEmpty = inputValue.trim().length === 0
    const newDate = errorsExist || inputEmpty ? null : renderedMoment.toDate()

    syncInput(newDate ? moment.tz(newDate, timezone) : priorSelectedMoment.current)
    onSelectedDateChange(newDate)

    if (inputDetails?.method === 'pick') {
      const date = inputDetails.value

      setInputDetails(null)

      log({
        id: widgetId,
        method: 'pick',
        parsed: (newDate && newDate.toISOString()) || undefined,
        value: date
      })
    } else if (inputDetails?.method === 'paste') {
      const pastedValue = inputDetails.value

      setInputDetails(null)

      log({
        id: widgetId,
        method: 'paste',
        parsed: (newDate && newDate.toISOString()) || undefined,
        value: pastedValue
      })
    } else if (!inputEmpty) {
      log({
        id: widgetId,
        method: 'type',
        parsed: (newDate && newDate.toISOString()) || undefined,
        value: inputValue.trim()
      })
    }
    onBlur?.(event)
  }

  function handleKey(e: KeyboardEvent) {
    if (e.key === 'Enter') {
      handleBlur(e)
    }
  }

  function trackPasteEvent(e) {
    setInputDetails({
      method: 'paste',
      value: e.clipboardData.getData('text')
    })
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
      onPaste={trackPasteEvent}
      onKeyUp={handleKey}
      isInline
      placement={placement}
      messages={messages.concat(internalMessages)}
      isShowingCalendar={isShowingCalendar}
      onBlur={handleBlur}
      onFocus={onFocus}
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
      display={display}
      data-testid={dataTestid}
      size={size}
    >
      {renderDays()}
    </DateInput>
  )
}
