/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useRef, useCallback, useEffect, useMemo, useState} from 'react'
import moment, {type Moment} from 'moment-timezone'
import * as tz from '@instructure/moment-utils'
import {DateInput2} from '@instructure/ui-date-input'
import {IconWarningSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

import type {ReactNode, KeyboardEvent, SyntheticEvent} from 'react'
import type {DateInput2Props} from '@instructure/ui-date-input'

type Messages = DateInput2Props['messages']

// This is a little gross, but as written this component can return either the original
// SyntheticEvent from the DateInput onBlur handler, -OR- a KeyboardEvent from the
// DateInput onKeyUp handler. Rather than change this component's behavior, we will just
// create this union type. It doesn't look like anything that uses this component and is
// making use of the onBlur callback is paying any attention to the actual event anyway.
type BlurReturn = SyntheticEvent<Element, Event> | KeyboardEvent<DateInput2Props>

const I18n = createI18nScope('app_shared_components_canvas_date_time')

const EARLIEST_YEAR = 1980 // do not allow any manually entered year before this

export type CanvasDateInput2Props = {
  /**
   * Represents the initial date to be selected. May be `undefined` for no selected date.
   */
  selectedDate?: string | null
  /**
   * Passed along to `DateInput2`, specifies the input label.
   */
  renderLabel?: ReactNode
  /**
   * Passed along to `DateInput2`, can be used to describe messages and validation for the input. Note that this
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
  onFocus?: React.FocusEventHandler<DateInput2Props & Element> | undefined
  /**
   * Passed down to `DateInput2`. Specifies if interaction with the input is enabled, disabled, or read-only. Read-only
   * prevents interactions, but is styled as if it were enabled.
   */
  interaction: DateInput2Props['interaction']
  /**
   * Passed down to `DateInput2`.
   */
  locale?: string
  onRequestValidateDate?: (event: SyntheticEvent<EventTarget>) => boolean
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
   * Passed along to `DateInput2`. Controls width of the input. Defaults to `null`, which leaves width setting up to
   * `size` prop.
   */
  width?: string
  /**
   * data test id for test selection
   */
  /**
   * Specify which date(s) will be shown as disabled in the calendar.
   * You can either supply an array of ISO8601 timeDate strings or
   * a function that will be called for each date shown in the calendar.
   */
  disabledDates?: string[] | ((isoDateToCheck: string) => boolean)
  dataTestid?: string
  /**
   * Specifies the input size. One of: small medium large
   */
  size?: DateInput2Props['size']
  /**
   * Controls whether the input is rendered inline with other elements or if it
   * is rendered as a block level element.
   */
  isInline?: boolean
  /**
   * Passed on to `DateInput2`. Text to show when input is empty.
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
  /**
   * Provides a ref to the underlying input element.
   */
  inputRef?: (element: HTMLInputElement | null) => void
}

export default function CanvasDateInput2({
  dataTestid,
  defaultToToday,
  disabledDates,
  formatDate,
  isInline,
  inputRef,
  interaction = 'enabled',
  invalidDateMessage,
  locale,
  messages = [], // message type 'newError' to be used for validation error messages
  onBlur,
  onFocus,
  onRequestValidateDate,
  onSelectedDateChange,
  placeholder = '',
  renderLabel = <span>{I18n.t('Choose a date')}</span>,
  selectedDate,
  timezone = ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone,
  width,
  withRunningValue,
}: CanvasDateInput2Props) {
  const todayMoment = moment().tz(timezone)

  const selectedMoment = useMemo(
    () => (selectedDate ? moment.tz(selectedDate, timezone) : null),
    [selectedDate, timezone],
  )

  const [inputValue, setInputValue] = useState('')
  const [renderedMoment, setRenderedMoment] = useState(selectedMoment || todayMoment)
  const [internalMessages, setInternalMessages] = useState<typeof messages>([])

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
    [],
  )

  const parseDate = (timezone: string) => (formattedDate: string) =>
    tz.parse(formattedDate, timezone)

  const syncInput = useCallback(
    (newMoment: Moment | null) => {
      const newInputValue = newMoment && newMoment.isValid() ? formatDate(newMoment.toDate()) : ''
      setInputValue(newInputValue)
      setInternalMessages([])
      setRenderedMoment(newMoment || todayMoment)
    },
    [formatDate, todayMoment],
  )

  useEffect(() => {
    if (isDifferentMoment(selectedMoment, priorSelectedMoment.current)) {
      if (defaultToToday && isInError()) return
      syncInput(selectedMoment)
      // now that we've done the check, we can update this value
      priorSelectedMoment.current = selectedMoment
    }
  }, [selectedMoment, isInError, syncInput, isDifferentMoment, selectedDate, defaultToToday])

  function invalidText(text: string) {
    if (typeof invalidDateMessage === 'function') return invalidDateMessage(text)
    if (typeof invalidDateMessage === 'undefined')
      return (
        <View textAlign="center">
          <View as="div" display="inline-block" margin="0 xxx-small xx-small 0">
            <IconWarningSolid />
          </View>
          {I18n.t('Invalid date format')}
        </View>
      )
    return invalidDateMessage
  }

  function handleChange(event: React.SyntheticEvent, inputValue: string, _utcDateString: string) {
    setInputValue(inputValue)
    const newDate = parseDate(timezone)(inputValue)
    if (newDate) {
      const year = newDate.getFullYear()
      if (year < EARLIEST_YEAR) {
        setInternalMessages([
          {
            type: 'error',
            text: I18n.t('Year %{year} is too far in the past', {year: String(year)}),
          },
        ])
        return
      }
      const msgs: Messages = withRunningValue ? [{type: 'success', text: formatDate(newDate)}] : []
      setRenderedMoment(moment.tz(newDate, timezone))
      setInternalMessages(msgs)
      // If the change happens due to calendar day click, input should be synced
      if (event.type === 'click') {
        syncInput(newDate ? moment.tz(newDate, timezone) : priorSelectedMoment.current)
        onSelectedDateChange(newDate, 'pick')
      }
      return
    }
    if (inputValue === '') {
      setInternalMessages([])
    } else {
      const text = invalidText(inputValue)
      setInternalMessages([{type: 'error', text}])
    }
  }

  function handleKey(e: KeyboardEvent<DateInput2Props & Element>) {
    if (e.key === 'Enter') {
      handleBlur(e)
    }
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

    onBlur?.(event)
  }

  return (
    <DateInput2
      renderLabel={renderLabel}
      locale={locale || ENV?.LOCALE || navigator.language}
      value={inputValue}
      onChange={handleChange}
      isInline={isInline}
      messages={messages.concat(internalMessages)}
      onBlur={handleBlur}
      onFocus={onFocus}
      onKeyUp={handleKey}
      timezone={timezone}
      onRequestValidateDate={onRequestValidateDate}
      interaction={interaction}
      width={width}
      disabledDates={disabledDates}
      data-testid={dataTestid}
      placeholder={placeholder}
      dateFormat={{formatter: formatDate, parser: parseDate(timezone)}}
      screenReaderLabels={{
        calendarIcon: I18n.t('Choose a date'),
        prevMonthButton: I18n.t('Previous month'),
        nextMonthButton: I18n.t('Next month'),
      }}
      inputRef={inputRef}
    />
  )
}
