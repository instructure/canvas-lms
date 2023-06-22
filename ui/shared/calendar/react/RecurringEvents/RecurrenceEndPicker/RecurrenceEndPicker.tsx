/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import moment from 'moment-timezone'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
// @ts-expect-error
import {px} from '@instructure/ui-utils'
// @ts-expect-error
import {RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {DEFAULT_COUNT, MAX_COUNT} from '../RRuleHelper'

import {useScope} from '@canvas/i18n'

const I18n = useScope('calendar_custom_recurring_event_end_picker')

export type ModeValues = 'ON' | 'AFTER'
export type OnRecurrenceEndChangeType = {
  until?: string
  count?: number
}

export type RecurrenceEndPickerProps = {
  dtstart: string
  locale: string
  timezone: string
  courseEndAt?: string
  until?: string
  count?: number
  onChange: (state: OnRecurrenceEndChangeType) => void
}

const makeDefaultCount = (count: number | undefined) =>
  typeof count === 'number' && count > 0 && count <= MAX_COUNT ? count : DEFAULT_COUNT

export default function RecurrenceEndPicker({
  dtstart,
  locale,
  timezone,
  courseEndAt,
  until,
  count,
  onChange,
}: RecurrenceEndPickerProps) {
  const [eventStart] = useState<string>(() => {
    return dtstart
      ? moment.tz(dtstart, timezone).toISOString(true)
      : moment().tz(timezone).toISOString(true)
  })
  const [mode, setMode] = useState<ModeValues>(() => {
    if (until) return 'ON'
    return 'AFTER'
  })
  const [untilDate, setUntilDate] = useState<string | undefined>(() => {
    // to be consistent with what is returned from DateInput when the date
    // is changed, initialize untilDate to be as the start of the day
    if (until !== undefined)
      return moment.tz(until, timezone).startOf('day').format('YYYY-MM-DDTHH:mm:ssZ')
    const start = moment.tz(eventStart, timezone).startOf('day')
    return start.add(1, 'year').format('YYYY-MM-DDTHH:mm:ssZ')
  })
  const [countNumber, setCountNumber] = useState<number | undefined>(makeDefaultCount(count))

  const dateFormatter = new Intl.DateTimeFormat(locale, {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    timeZone: timezone,
  })

  useEffect(() => {
    if (count === undefined && until === undefined) {
      fireOnChange(mode, undefined, countNumber)
    }
    // on init, tell our parent if we cooked up a count
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (until) {
      setMode('ON')
      setUntilDate(until)
    } else {
      setMode('AFTER')
      setCountNumber(makeDefaultCount(count))
    }
  }, [count, until])

  const formatCourseEndDate = (date?: string): string => {
    if (!date) return ''
    return dateFormatter.format(moment.tz(date, timezone).toDate())
  }

  const fireOnChange = useCallback(
    (newMode, newUntil, newCount) => {
      if (newMode === 'ON') {
        if (newUntil === undefined) return
        onChange({until: newUntil, count: undefined})
      } else if (newMode === 'AFTER') {
        onChange({until: undefined, count: newCount})
      } else {
        onChange({until: undefined, count: undefined})
      }
    },
    [onChange]
  )

  const handleModeChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>): void => {
      const newMode = event.target.value as ModeValues
      setMode(newMode)
      fireOnChange(newMode, untilDate, countNumber)
    },
    [fireOnChange, untilDate, countNumber]
  )

  const handleCountChange = useCallback(
    (_event: Event, value: string | number): void => {
      const cnt = typeof value === 'string' ? parseInt(value, 10) : value
      if (Number.isNaN(cnt)) return
      if (cnt < 1) return
      setCountNumber(cnt)
      fireOnChange(mode, untilDate, cnt)
    },
    [fireOnChange, mode, untilDate]
  )

  const handleDateChange = useCallback(
    (date: Date | null) => {
      if (!date) return
      if (date.constructor.name !== 'Date') return
      // js Date cannot parse ISO strings with milliseconds
      const newISODate = moment
        .tz(date, timezone)
        .toISOString(true)
        .replace(/\.\d+/, '')
        .replace(/\+00:00/, 'Z')
      setUntilDate(newISODate)
      fireOnChange(mode, newISODate, countNumber)
    },
    [timezone, fireOnChange, mode, countNumber]
  )

  const gridStyle = {
    display: 'grid',
    gridTemplateColumns: 'min-content min-content',
    gridTemplateRows: 'auto auto',
    rowGap: '0.5rem',
    columnGap: '0.75rem',
    justifyItems: 'start',
    alignItems: 'center',
  }
  const alignMe = {
    marginTop: '0.75rem',
    alignSelf: 'start',
  }

  return (
    <FormFieldGroup description={I18n.t('Ends:')} layout="stacked" rowSpacing="small">
      <div style={gridStyle}>
        <div style={alignMe}>
          <RadioInput
            name="end"
            value="ON"
            label={I18n.t('on')}
            checked={mode === 'ON'}
            onChange={handleModeChange}
          />
        </div>
        <CanvasDateInput
          interaction={mode === 'ON' ? 'enabled' : 'disabled'}
          locale={locale}
          timezone={timezone}
          renderLabel={<ScreenReaderContent>{I18n.t('date')}</ScreenReaderContent>}
          selectedDate={untilDate}
          formatDate={date => dateFormatter.format(date)}
          onSelectedDateChange={handleDateChange}
          messages={
            courseEndAt
              ? [
                  {
                    type: 'hint',
                    text: I18n.t('Course ends %{endat}', {endat: formatCourseEndDate(courseEndAt)}),
                  },
                ]
              : undefined
          }
        />
        <div style={alignMe}>
          <RadioInput
            name="end"
            value="AFTER"
            label={I18n.t('after')}
            checked={mode === 'AFTER'}
            onChange={handleModeChange}
          />
        </div>
        <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
          <NumberInput
            display="inline-block"
            interaction={mode === 'AFTER' ? 'enabled' : 'disabled'}
            messages={[{type: 'hint', text: I18n.t('Maximum %{max}', {max: MAX_COUNT})}]}
            renderLabel={<ScreenReaderContent>{I18n.t('occurences')}</ScreenReaderContent>}
            value={countNumber}
            width={`${px('3em') + px('4rem')}px`}
            onChange={handleCountChange}
            onIncrement={(event: Event) => {
              if (countNumber === undefined || Number.isNaN(countNumber)) return
              handleCountChange(event, countNumber + 1)
            }}
            onDecrement={(event: Event) => {
              if (countNumber === undefined || Number.isNaN(countNumber)) return
              handleCountChange(event, countNumber - 1)
            }}
          />
          <div style={alignMe}>
            <Text as="span">{I18n.t('occurrences')}</Text>
          </div>
        </div>
      </div>
    </FormFieldGroup>
  )
}
