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
import {FormField, FormFieldGroup} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
import {px} from '@instructure/ui-utils'
import {RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {IconWarningLine} from '@instructure/ui-icons'
import {DEFAULT_COUNT, MAX_COUNT} from '../RRuleHelper'
import type {FrequencyValue} from '../types'

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
  freq: FrequencyValue
  interval: number
  courseEndAt?: string
  until?: string
  count?: number
  onChange: (state: OnRecurrenceEndChangeType) => void
}

export type InstuiMessage = {
  type: 'hint' | 'error'
  text: string
}

export const CountValidator = {
  makeDefaultCount: (count: number | undefined) =>
    typeof count === 'number' && count > 0 && count <= MAX_COUNT ? count : DEFAULT_COUNT,

  hint: (): InstuiMessage[] => [],

  invalidCount: (): InstuiMessage[] => [
    {
      type: 'error',
      text: I18n.t('Must be between 1 and %{max}', {
        max: MAX_COUNT,
      }),
    },
  ],

  countTooSmall: (): InstuiMessage[] => [
    {
      type: 'error',
      text: I18n.t('Must have at least 1 occurrence'),
    },
  ],

  countTooLarge: (): InstuiMessage[] => [
    {
      type: 'error',
      text: I18n.t('Exceeds %{max} occurrences limit', {
        max: MAX_COUNT,
      }),
    },
  ],

  countNotWhole: (): InstuiMessage[] => [
    {
      type: 'error',
      text: I18n.t('Must be a whole number'),
    },
  ],

  isValidCount: (cnt: number | undefined, mode: ModeValues): boolean => {
    if (mode === 'ON') return true // we don't care
    // @ts-expect-error isInteger will prevent the following checks being done on undefined, but ts doesn't know that
    if (Number.isInteger(cnt) && cnt > 0 && cnt <= MAX_COUNT) return true
    return false
  },

  getCountMessage: (count: number | undefined): InstuiMessage[] | undefined => {
    if (count === undefined) return CountValidator.hint()
    if (Number.isNaN(count)) return CountValidator.invalidCount()
    if (!Number.isInteger(count)) return CountValidator.countNotWhole()
    if (count < 1) return CountValidator.countTooSmall()
    if (count > MAX_COUNT) return CountValidator.countTooLarge()
    return undefined
  },
}

export const UntilValidator = {
  hint: (courseEndAt: string | undefined): InstuiMessage[] => {
    return courseEndAt !== undefined ? UntilValidator.courseEndHint(courseEndAt) : []
  },

  courseEndHint: (courseEndAt: string): InstuiMessage[] => [
    {
      type: 'hint',
      text: I18n.t('Course ends %{endat}', {endat: courseEndAt}),
    },
  ],

  tooSoon: (): InstuiMessage[] => [
    {
      type: 'error',
      text: I18n.t('Until date must be after the event start date'),
    },
  ],

  tooMany: (): InstuiMessage[] => [
    {
      type: 'error',
      text: I18n.t('Exceeds %{max} events.', {max: MAX_COUNT}),
    },
    {
      type: 'error',
      text: I18n.t('Please pick an earlier date'),
    },
  ],

  freq2Diff: (freq: FrequencyValue): moment.unitOfTime.Diff => {
    switch (freq) {
      case 'DAILY':
        return 'days'
      case 'WEEKLY':
        return 'weeks'
      case 'MONTHLY':
        return 'months'
      case 'YEARLY':
        return 'years'
    }
  },

  occurrences(
    start: moment.Moment,
    until: moment.Moment,
    freq: FrequencyValue,
    interval: number
  ): number {
    const days = until.diff(start, UntilValidator.freq2Diff(freq))
    return Math.floor(days / interval) + 1
  },

  getUntilMessage: (
    until: string | undefined,
    timezone: string,
    eventStart: string,
    mode: ModeValues,
    freq: FrequencyValue,
    interval: number,
    courseEndAt: string | undefined
  ): InstuiMessage[] | undefined => {
    if (mode === 'AFTER') {
      return UntilValidator.hint(courseEndAt)
    }
    if (until === undefined) return UntilValidator.hint(courseEndAt)
    const untilDate = moment.tz(until, timezone)
    const eventStartDate = moment.tz(eventStart, timezone)
    if (untilDate.isBefore(eventStartDate)) return UntilValidator.tooSoon()

    return UntilValidator.occurrences(eventStartDate, untilDate, freq, interval) > MAX_COUNT
      ? UntilValidator.tooMany()
      : UntilValidator.hint(courseEndAt)
  },
}

export default function RecurrenceEndPicker({
  dtstart,
  locale,
  timezone,
  courseEndAt,
  freq,
  interval,
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
      return moment.tz(until, timezone).endOf('day').format('YYYY-MM-DDTHH:mm:ssZ')
    const start = moment.tz(eventStart, timezone).endOf('day')
    return start.add(1, 'year').format('YYYY-MM-DDTHH:mm:ssZ')
  })
  const [countNumber, setCountNumber] = useState<number | undefined>(
    CountValidator.makeDefaultCount(count)
  )
  const [countValue, setCountValue] = useState<string>(countNumber?.toString() || '')
  const [countMessage, setCountMessage] = useState<InstuiMessage[] | undefined>(
    CountValidator.hint()
  )

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
      if (count !== undefined && !Number.isNaN(count)) {
        setCountNumber(count)
      }
    }
  }, [count, until])

  const formatCourseEndDate = (date?: string): string | undefined => {
    if (!date) return undefined
    return dateFormatter.format(moment.tz(date, timezone).toDate())
  }

  const fireOnChange = useCallback(
    (newMode, newUntil, newCount): void => {
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
      if (newMode === 'ON') {
        setCountMessage(CountValidator.hint())
      } else {
        setCountMessage(CountValidator.getCountMessage(countNumber))
      }
      setMode(newMode)
      fireOnChange(newMode, untilDate, countNumber)
    },
    [fireOnChange, untilDate, countNumber]
  )

  const handleCountChange = useCallback(
    (_event, value: string | number): void => {
      const cnt = typeof value === 'string' ? parseFloat(value) : value
      setCountNumber(cnt)
      setCountValue(value.toString())
      if (CountValidator.isValidCount(cnt, mode)) {
        setCountMessage(CountValidator.hint())
        fireOnChange(mode, untilDate, cnt)
      } else {
        setCountMessage(CountValidator.getCountMessage(cnt))
        fireOnChange(mode, untilDate, undefined)
      }
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
        .endOf('day')
        .toISOString(true)
        .replace(/\.\d+/, '')
        .replace(/\+00:00/, 'Z')
      if (newISODate === untilDate) return
      setUntilDate(newISODate)
      fireOnChange(mode, newISODate, countNumber)
    },
    [timezone, untilDate, fireOnChange, mode, countNumber]
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
          dataTestid="recurrence-ends-on-input"
          interaction={mode === 'ON' ? 'enabled' : 'disabled'}
          locale={locale}
          timezone={timezone}
          renderLabel={<ScreenReaderContent>{I18n.t('date')}</ScreenReaderContent>}
          selectedDate={untilDate}
          formatDate={date => dateFormatter.format(date)}
          onSelectedDateChange={handleDateChange}
          messages={UntilValidator.getUntilMessage(
            untilDate,
            timezone,
            eventStart,
            mode,
            freq,
            interval,
            formatCourseEndDate(courseEndAt)
          )}
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
        <FormField
          id="recurrence-end-count"
          messages={countMessage}
          label={<ScreenReaderContent>{I18n.t('occurrences')}</ScreenReaderContent>}
        >
          <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
            <NumberInput
              data-testid="recurrence-end-count-input"
              display="inline-block"
              interaction={mode === 'AFTER' ? 'enabled' : 'disabled'}
              renderLabel={() => ''}
              value={countValue}
              width={`${px('3em') + px('4rem')}px`}
              onChange={handleCountChange}
              onIncrement={event => {
                if (
                  countNumber === undefined ||
                  Number.isNaN(countNumber) ||
                  countNumber >= MAX_COUNT
                )
                  return
                handleCountChange(event, Math.floor(countNumber) + 1)
              }}
              onDecrement={event => {
                if (countNumber === undefined || Number.isNaN(countNumber) || countNumber <= 1)
                  return
                handleCountChange(event, Math.ceil(countNumber) - 1)
              }}
              messages={
                CountValidator.isValidCount(countNumber, mode) ? [] : [{text: '', type: 'error'}]
              }
            />
            <div style={{...alignMe, whiteSpace: 'nowrap'}}>
              <Text as="span">{I18n.t('occurrences (max %{max})', {max: MAX_COUNT})}</Text>
              {!CountValidator.isValidCount(countNumber, mode) && (
                <span style={{marginInlineStart: '0.5rem'}}>
                  <IconWarningLine color="error" />
                </span>
              )}
            </div>
          </div>
        </FormField>
      </div>
    </FormFieldGroup>
  )
}
