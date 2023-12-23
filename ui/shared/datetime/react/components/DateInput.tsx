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
import React, {useRef, useCallback, useEffect, useState} from 'react'
import moment, {type Moment} from 'moment-timezone'
import * as tz from '../../index'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Calendar} from '@instructure/ui-calendar'
import {DateInput} from '@instructure/ui-date-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndSolid, IconArrowOpenStartSolid} from '@instructure/ui-icons'

import type {ViewProps} from '@instructure/ui-view'
import type {
  ClipboardEvent,
  ReactNode,
  MouseEvent,
  ChangeEvent,
  FocusEvent,
  KeyboardEvent,
  SyntheticEvent,
} from 'react'
import type {DateInputProps} from '@instructure/ui-date-input'

type Messages = DateInputProps['messages']

// This is a little gross, but as written this component can return either the original
// SyntheticEvent from the DateInput onBlur handler, -OR- a KeyboardEvent from the
// DateInput onKeyUp handler. Rather than change this component's behavior, we will just
// create this union type. It doesn't look like anything that uses this component and is
// making use of the onBlur callback is paying any attention to the actual event anyway.
type BlurReturn = SyntheticEvent<Element, Event> | KeyboardEvent<DateInputProps>

const I18n = useI18nScope('app_shared_components_canvas_date_time')

export type CanvasDateInputProps = {
  /**
   * Represents the initial date to be selected. May be `undefined` for no selected date.
   */
  selectedDate?: string | null
  /**
   * Passed along to `DateInput`, specifies the input label.
   */
  renderLabel?: ReactNode
  /**
   * Passed along to `DateInput`, can be used to describe messages and validation for the input. Note that this
   * component may display its own messages as well.
   */
  messages?: Messages
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
  formatDate: (date: Date) => string
  /**
   * A callback function which is called when a date has been selected, either by typing it in and tabbing out of the
   * field, or by clicking on a date in the calendar. It is called with one argument, a JS `Date` object. If the input
   * is a bad date (such as if the user types something unparseable) the value passed will evaluate to Boolean `false`.
   */
  onSelectedDateChange: (date: Date | null, dateInputType: 'pick' | 'other' | 'error') => void
  /**
   * focus and blur event handlers
   */
  onBlur?: (event: BlurReturn) => void // see comment above the type definition for BlurReturn
  onFocus?: (event: FocusEvent<DateInputProps>) => void
  /**
   * Passed along to `DateInput`. Specifies if interaction with the input is enabled, disabled, or read-only. Read-only
   * prevents interactions, but is styled as if it were enabled.
   */
  interaction: DateInputProps['interaction']
  locale?: string
  onRequestValidateDate?: (event: SyntheticEvent<EventTarget>) => boolean
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
  layout?: DateInputProps['layout']
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
  size?: DateInputProps['size']
  /**
   * Specifies the display property of the container. One of: inline-block block
   */
  display?: DateInputProps['display']
  /**
   * Passed on to `DateInput`. Text to show when input is empty.
   */
  placeholder?: string
  /**
   * Controls the what happens when the text input blurs.
   * If false, the behavior is as it always has been:
   *   - when the input is empty, leave it empty
   *   - when there is an invalid date, clear the input
   * If true:
   *   - when the input is empty, set it to today
   *   - when the input is an invalid date, leave what was entered in place
   *     and call onSelectedDateChange(null, 'error')
   */
  defaultToToday?: boolean
}

/**
 * This is a helper component that interfaces with InstUI 7's DateInput. DateInput is highly un-opinionated and throws a
 * lot of formatting and event handling over the fence to the caller, some of which can get rather involved. So we deal
 * with much of it here.
 */
export default function CanvasDateInput({
  dataTestid,
  dateIsDisabled,
  defaultToToday,
  display,
  formatDate,
  interaction = 'enabled',
  invalidDateMessage,
  layout = 'stacked',
  locale: specifiedLocale,
  messages = [],
  onBlur,
  onFocus,
  onRequestValidateDate,
  onSelectedDateChange,
  placeholder = '',
  placement = 'bottom center',
  renderLabel = <span>{I18n.t('Choose a date')}</span>,
  selectedDate,
  size,
  timezone = ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone,
  width,
  withRunningValue,
}: CanvasDateInputProps) {
  const todayMoment = moment().tz(timezone)

  const [selectedMoment, setSelectedMoment] = useState(
    selectedDate ? moment.tz(selectedDate, timezone) : null
  )
  const [inputValue, setInputValue] = useState('')
  const [isShowingCalendar, setIsShowingCalendar] = useState(false)
  const [renderedMoment, setRenderedMoment] = useState(selectedMoment || todayMoment)
  const [internalMessages, setInternalMessages] = useState<typeof messages>([])
  const [inputDetails, setInputDetails] = useState<{
    method: 'paste' | 'pick'
    value: string
  } | null>(null)

  const priorSelectedMoment = useRef<Moment | null>(null)

  const isInError = useCallback(() => {
    const inputEmpty = inputValue?.length === 0
    return inputEmpty
      ? false
      : internalMessages.filter(m => m.type === 'error').length > 0 || !renderedMoment.isValid()
  }, [inputValue, internalMessages, renderedMoment])

  const isDifferentMoment = useCallback(
    (firstMoment: Moment | null, secondMoment: Moment | null) => {
      const changedNull =
        (firstMoment === null && secondMoment !== null) ||
        (firstMoment !== null && secondMoment == null)
      const changedValue = firstMoment && firstMoment.isValid() && !firstMoment.isSame(secondMoment)
      return changedNull || changedValue
    },
    []
  )

  const syncInput = useCallback(
    (newMoment: Moment | null) => {
      const newInputValue = newMoment && newMoment.isValid() ? formatDate(newMoment.toDate()) : ''
      setInputValue(newInputValue)
      setInternalMessages([])
      setRenderedMoment(newMoment || todayMoment)
    },
    [formatDate, todayMoment]
  )

  useEffect(() => {
    setSelectedMoment(selectedDate ? moment.tz(selectedDate, timezone) : null)
  }, [selectedDate, timezone])

  useEffect(() => {
    if (isDifferentMoment(selectedMoment, priorSelectedMoment.current)) {
      if (defaultToToday && isInError()) return
      syncInput(selectedMoment)
      // now that we've done the check, we can update this value
      priorSelectedMoment.current = selectedMoment
    }
  }, [selectedMoment, isInError, syncInput, isDifferentMoment, selectedDate, defaultToToday])

  function generateMonthMoments() {
    const firstMoment = moment.tz(renderedMoment, timezone).startOf('month').startOf('week')
    // @ts-ignore DAY_COUNT is not included in instructure-ui 7 types
    return [...Array(Calendar.DAY_COUNT).keys()].map(index =>
      firstMoment.clone().add(index, 'days')
    )
  }

  function renderDays() {
    // This is expensive, so only do it if the calendar is open
    if (!isShowingCalendar) return undefined

    const locale = specifiedLocale || ENV?.LOCALE || navigator.language

    const labelFormatter = new Intl.DateTimeFormat(locale, {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      timeZone: timezone,
    })

    const dayFormat = new Intl.DateTimeFormat(locale, {
      day: 'numeric',
      timeZone: timezone,
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

  function invalidText(text: string) {
    if (typeof invalidDateMessage === 'function') return invalidDateMessage(text)
    if (typeof invalidDateMessage === 'undefined') return I18n.t('Invalid Date')
    return invalidDateMessage
  }

  function handleChange(_event: ChangeEvent<HTMLInputElement>, {value}: {value: string}) {
    setInputValue(value)
    // If we have been asked to show the running value, hide the popup
    if (isShowingCalendar && withRunningValue) handleHideCalendar()
    const newDate = tz.parse(value, timezone)
    if (newDate) {
      const msgs: Messages = withRunningValue ? [{type: 'success', text: formatDate(newDate)}] : []
      setRenderedMoment(moment.tz(newDate, timezone))
      setInternalMessages(msgs)
    } else if (value === '') {
      setInternalMessages([])
    } else {
      const text = invalidText(value)
      setInternalMessages([{type: 'error', text}])
    }
  }

  function handleDayClick(_event: MouseEvent<ViewProps>, {date}: {date: string}) {
    const parsedMoment = moment.tz(date, timezone)
    let input = parsedMoment
    if (selectedDate) {
      const selectedMoment_ = moment.tz(selectedDate, timezone)
      if (selectedMoment_.isSame(parsedMoment, 'day')) {
        input = selectedMoment_
      }
    }
    syncInput(input)
    onSelectedDateChange(parsedMoment.toDate(), 'pick')
    setInputDetails({method: 'pick', value: date})
  }

  function handleBlur(event: BlurReturn) {
    const inputEmpty = inputValue.trim().length === 0
    const errorsExist = isInError()
    let newDate = null

    if (defaultToToday) {
      if (errorsExist) {
        onSelectedDateChange(null, 'error')
      } else {
        newDate = inputEmpty ? new Date() : renderedMoment.toDate()
        syncInput(newDate ? moment.tz(newDate, timezone) : priorSelectedMoment.current)
        onSelectedDateChange(newDate, 'other')
      }
    } else {
      newDate = errorsExist || inputEmpty ? null : renderedMoment.toDate()

      syncInput(newDate ? moment.tz(newDate, timezone) : priorSelectedMoment.current)
      onSelectedDateChange(newDate, 'other')
    }

    if (inputDetails?.method === 'pick') {
      setInputDetails(null)
    } else if (inputDetails?.method === 'paste') {
      setInputDetails(null)
    }
    onBlur?.(event)
  }

  function handleKey(e: KeyboardEvent<DateInputProps>) {
    if (e.key === 'Enter') {
      handleBlur(e)
    } else if (e.key === 'Escape') {
      setIsShowingCalendar(false)
    }
  }

  function trackPasteEvent(e: ClipboardEvent<DateInputProps>) {
    setInputDetails({
      method: 'paste',
      value: e.clipboardData?.getData('text') || '',
    })
  }

  function handleHideCalendar() {
    setIsShowingCalendar(false)
  }

  function handleShowCalendar(e: SyntheticEvent) {
    // Do not re-show the calendar if input was typing and we have been asked to
    // show the running value. For some reason DateInput reflects an InputEvent for
    // all typing EXCEPT for spaces, which come in as KeyboardEvents, so we have to
    // deal with both. 🤷🏼‍♂️
    const ne: unknown = e.nativeEvent
    if (withRunningValue) {
      if ((ne as InputEvent).constructor.name === 'InputEvent') return
      if ((ne as KeyboardEvent)?.key === ' ') {
        setInputValue(v => v + ' ')
        return
      }
    }
    setIsShowingCalendar(true)
  }

  function modifySelectedMoment(
    step: moment.DurationInputArg1,
    type?: moment.unitOfTime.DurationConstructor
  ) {
    // If we do not have a selectedMoment, we'll just select the first day of
    // the currently rendered month.
    const newMoment = selectedMoment
      ? selectedMoment.clone().add(step, type).startOf('day')
      : renderedMoment.clone().startOf('month')

    onSelectedDateChange(newMoment.toDate(), 'pick')
  }

  function modifyRenderedMoment(
    step: moment.DurationInputArg1,
    type?: moment.unitOfTime.DurationConstructor
  ) {
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

  function renderMonthChangeButton(direction: 'prev' | 'next') {
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
      isInline={true}
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
      onRequestValidateDate={onRequestValidateDate}
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
      placeholder={placeholder}
    >
      {renderDays()}
    </DateInput>
  )
}
