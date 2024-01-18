/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, {useState, useCallback, useRef} from 'react'
import {func, node, string} from 'prop-types'
import {TimeSelect} from '@instructure/ui-time-select'
import {FormFieldGroup} from '@instructure/ui-form-field'
import DateInput from './DateInput'
import {utcTimeOffset, utcDateOffset} from '../../changeTimezone'

const I18n = useI18nScope('date_time_input')

/*
 *  This is a helper component that implements a single date and time picker,
 *  replacing functionality lost when DateTimeInput was removed in InstUI 7.
 *  It makes use of DateInput for the datepicker.
 *
 *  props:
 *  value  [string, ISO date format]
 *     current value of the selected date/time (JS Date)
 *
 *  onChange  [func]
 *
 *  locale  [string]
 *     locale to use (defaults to ENV.LOCALE and thence the browser's setting)
 *
 *  timezone  [string]
 *     timezone to use (defaults to ENV.TIMEZONE and thence to the browser's setting)
 *
 *  dateLabel  [string]
 *     label to use for the date selector portion
 *
 *  timeLabel  [string]
 *     label to use for the time selector
 *
 *  description  [JSX | string]
 *     Text that describes the entire date and time selector. Can be a string or
 *     a JSX node. Can be <ScreenReaderContent> for a11y purposes.
 */

const TICKS_IN_DAY = 24 * 60 * 60 * 1000

const goodMessage = text => [{type: 'success', text}]

function toTimeComponents(date) {
  const jsDate = date instanceof Date ? date : new Date(date)
  const n = jsDate.getTime()
  const datePart = TICKS_IN_DAY * Math.trunc(n / TICKS_IN_DAY)
  const timePart = n % TICKS_IN_DAY
  return [datePart, timePart]
}

function fromTimeComponents(components, correction = 0) {
  const combined = components[0] + components[1] + correction
  return new Date(combined).toISOString()
}

function DateTimeInput(props) {
  const locale = props.locale || ENV?.LOCALE || navigator.language
  const timezone =
    props.timezone || ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone
  const inputValue = props.value || new Date().toISOString()
  const prevValue = useRef(inputValue)
  const [dateValue, setDateValue] = useState(() => toTimeComponents(inputValue))
  const [timeValue, setTimeValue] = useState(() => toTimeComponents(inputValue))

  // date string in the current state
  const oldDateValue = new Date(dateValue[0] + dateValue[1])
  const oldTimeValue = new Date(timeValue[0] + timeValue[1])

  // Returns the difference in timezone offset between the two argument Dates
  // This will be nonzero if one date is in Summer Time and the other one is not.
  const dstCorr = (baseDate, date) =>
    utcTimeOffset(baseDate, timezone) - utcTimeOffset(date, timezone)

  function onChange(newValue) {
    const jsDate = newValue instanceof Date ? newValue : new Date(newValue)
    if (jsDate.getTime() !== new Date(inputValue).getTime()) {
      props.onChange(jsDate.toISOString())
    }
  }

  const formatDate = useCallback(
    date => {
      const jsDate = date instanceof Date ? date : new Date(date)
      const formatter = new Intl.DateTimeFormat(locale, {
        weekday: 'short',
        month: 'long',
        day: 'numeric',
        year: 'numeric',
        timeZone: timezone,
      })
      return formatter.format(jsDate)
    },
    [locale, timezone]
  )

  const formatDateTime = useCallback(
    date => {
      const jsDate = date instanceof Date ? date : new Date(date)
      const formatter = new Intl.DateTimeFormat(locale, {
        weekday: 'short',
        month: 'long',
        day: 'numeric',
        year: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        timeZone: timezone,
      })
      return formatter.format(jsDate)
    },
    [locale, timezone]
  )

  function onDateUpdate(newDate) {
    let [d] = toTimeComponents(newDate)

    // DateInput returns only the base date, which if the UTC date is different
    // from the local date will be wrong. So correct that here.
    d += utcDateOffset(oldDateValue, timezone) * TICKS_IN_DAY

    if (d === dateValue[0]) return // no actual change

    // possibly correct for the fact that the new date is in a different summer time setting
    // than the old one. While it may be "correct" to adjust the time by an hour because of
    // the time change, that would probably not be expected behavior (a 4pm due date is a 4pm
    // due date in both December and May)
    d -= dstCorr(newDate, oldDateValue)
    setDateValue([d, timeValue[1]])
    const newValue = fromTimeComponents([d, timeValue[1]])
    onChange(newValue)
  }

  function onTimeUpdate(_e, data) {
    const [d, t] = toTimeComponents(data.value)
    if (t === timeValue[1]) return // no actual change

    const diff = d + t - timeValue[0] - timeValue[1] + dstCorr(oldTimeValue, oldDateValue)
    setTimeValue([d, t])
    onChange(new Date(dateValue[0] + dateValue[1] + diff))
  }

  // Saved value state should track a change in the incoming value prop
  if (prevValue.current !== inputValue) {
    prevValue.current = inputValue
    const [newDate, newTime] = toTimeComponents(inputValue)
    setDateValue([newDate, newTime])
    setTimeValue([timeValue[0], newTime])
  }

  const sendDate = fromTimeComponents(dateValue)
  const sendTime = fromTimeComponents(timeValue, -dstCorr(oldTimeValue, oldDateValue))

  return (
    <FormFieldGroup
      colSpacing={props.colSpacing || 'medium'}
      vAlign="top"
      layout={props.layout || 'stacked'}
      rowSpacing="small"
      messages={goodMessage(formatDateTime(inputValue))}
      description={props.description}
    >
      <DateInput
        renderLabel={props.dateLabel || I18n.t('Date')}
        formatDate={formatDate}
        selectedDate={sendDate}
        locale={locale}
        timezone="UTC"
        onSelectedDateChange={onDateUpdate}
        withRunningValue={true}
      />
      <TimeSelect
        renderLabel={props.timeLabel || I18n.t('Time')}
        value={sendTime}
        locale={locale}
        timezone={timezone}
        onChange={onTimeUpdate}
      />
    </FormFieldGroup>
  )
}

DateTimeInput.propTypes = {
  dateLabel: string,
  timeLabel: string,
  locale: string,
  timezone: string,
  onChange: func.isRequired,
  value: string,
  description: node.isRequired,
  colSpacing: string,
  layout: string,
}

function dontRerender(prevProps, props) {
  if (prevProps.value !== props.value) return false
  if (prevProps.dateLabel !== props.dateLabel) return false
  if (prevProps.timeLabel !== props.timeLabel) return false
  if (prevProps.locale !== props.locale) return false
  if (prevProps.timezone !== props.timezone) return false
  if (prevProps.description !== props.description) return false
  if (prevProps.colSpacing !== props.colSpacing) return false
  if (prevProps.layout !== props.layout) return false
  return true
}

export default React.memo(DateTimeInput, dontRerender)
