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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import moment from 'moment-timezone'
import WeekdayPicker from '../WeekdayPicker/WeekdayPicker'
import {useScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {NumberInput} from '@instructure/ui-number-input'
import {px} from '@instructure/ui-utils'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {
  AllRRULEDayValues,
  type FrequencyValue,
  type MonthlyModeValue,
  type SelectedDaysArray,
} from '../types'
import {
  cardinalDayInMonth,
  getMonthlyMode,
  getSelectTextWidth,
  getWeekdayName,
  isLastWeekdayInMonth,
  weekdaysFromMoment,
} from '../utils'

const I18n = useScope('calendar_custom_recurring_event_repeat_picker')

const {Option: SimpleSelectOption} = SimpleSelect as any

export type RepeatPickerProps = {
  locale: string
  timezone: string
  dtstart: string
  interval: number
  freq: FrequencyValue
  weekdays?: SelectedDaysArray
  pos?: number // 1: first, 2: second, ...
  onChange: (state: OnRepeatPickerChangeType) => void
}

export type OnRepeatPickerChangeType = {
  interval: number
  freq: FrequencyValue
  weekdays?: SelectedDaysArray
  monthdate?: number
  month?: number
  pos?: number
}

export const getByMonthdateString = (
  datetime: moment.Moment,
  locale: string,
  timezone: string
): string => {
  const cardinal = cardinalDayInMonth(datetime)
  const dayname = getWeekdayName(datetime, locale, timezone)
  const monthdateStrings = [
    I18n.t('on the first %{dayname}', {dayname}),
    I18n.t('on the second %{dayname}', {dayname}),
    I18n.t('on the third %{dayname}', {dayname}),
    I18n.t('on the fourth %{dayname}', {dayname}),
    I18n.t('on the fifth %{dayname}', {dayname}),
  ]
  return monthdateStrings[cardinal.cardinal - 1]
}

export const getLastWeekdayInMonthString = (dayname: string): string => {
  return I18n.t('on the last %{dayname}', {dayname})
}

export default function RepeatPicker({
  locale,
  timezone,
  dtstart,
  interval,
  freq,
  weekdays,
  pos,
  onChange,
}: RepeatPickerProps) {
  const [eventStart, setEventStart] = useState<moment.Moment>(moment(dtstart).tz(timezone))

  const [currInterval, setCurrInterval] = useState<number>(interval)
  const [currFreq, setCurrFreq] = useState<FrequencyValue>(freq)
  const [currWeekDays, setCurrWeekdays] = useState<SelectedDaysArray>(
    weekdays ?? weekdaysFromMoment(eventStart)
  )
  const [currPos, setCurrPos] = useState<number | undefined>(pos)
  const [currMonthlyMode, setCurrMonthlyMode] = useState<MonthlyModeValue>(() => {
    return getMonthlyMode(freq, weekdays, pos)
  })

  // I cannot get flexbox to make the monthly options select wide enough
  // so the value is not clipped. Let's calculate the space needed for
  // the max-width value string + all SimpleSelect's padding and such
  // (plus 2px, because it was needed), and use that to set SimpleSelect's
  // text input width
  const [monthlyOptionsWidth] = useState<string>(() => {
    const bydate = I18n.t('on day %{date}', {date: eventStart.date()})
    const byday = getByMonthdateString(eventStart, locale, timezone)
    return getSelectTextWidth([bydate, byday])
  })
  // ditto the freq picker
  const [freqPickerWidth] = useState<string>(() => {
    const d = I18n.t('Days')
    const m = I18n.t('MOnths')
    const w = I18n.t('Weeks')
    const y = I18n.t('Years')
    return getSelectTextWidth([d, m, w, y])
  })
  const activeElement = useRef<HTMLElement | null>(null)
  const freqRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    setEventStart(moment.tz(dtstart, timezone))
  }, [dtstart, timezone])

  useEffect(() => {
    setCurrInterval(interval)
    setCurrFreq(freq)
    setCurrWeekdays(weekdays ?? weekdaysFromMoment(eventStart))
    setCurrPos(pos)
    setCurrMonthlyMode(() => {
      return getMonthlyMode(freq, weekdays, pos)
    })
  }, [freq, interval, weekdays, pos, eventStart])

  useEffect(() => {
    if (activeElement.current != null && freqRef.current !== null) {
      activeElement.current = null
      freqRef.current.focus()
    }
  }, [freq])

  const fireOnChange = useCallback(
    (i, f, w, md, m, p) => {
      if (f === 'YEARLY') {
        onChange({
          interval: i,
          freq: f,
          weekdays: undefined,
          monthdate: md,
          month: m,
          pos: undefined,
        })
      } else if (f === 'MONTHLY') {
        onChange({interval: i, freq: f, weekdays: w, monthdate: md, month: m, pos: p})
      } else if (f === 'WEEKLY') {
        onChange({
          interval: i,
          freq: f,
          weekdays: w,
          monthdate: undefined,
          month: undefined,
          pos: undefined,
        })
      } else if (f === 'DAILY') {
        onChange({
          interval: i,
          freq: f,
          weekdays: undefined,
          monthdate: undefined,
          month: undefined,
          pos: undefined,
        })
      }
    },
    [onChange]
  )

  const handleChangeMonthlyMode = useCallback(
    (_event, {value}) => {
      const newMonthlyMode = value as MonthlyModeValue

      setCurrMonthlyMode(newMonthlyMode)
      if (newMonthlyMode === 'BYMONTHDAY') {
        const eventWeekday = AllRRULEDayValues[eventStart.day()]
        setCurrWeekdays([eventWeekday])
        const newPos = cardinalDayInMonth(eventStart).cardinal
        setCurrPos(newPos)
        fireOnChange(currInterval, 'MONTHLY', [eventWeekday], undefined, undefined, newPos)
      } else if (newMonthlyMode === 'BYMONTHDATE') {
        fireOnChange(currInterval, 'MONTHLY', undefined, eventStart.date(), undefined, undefined)
      } else {
        // bypos, only get here if it's "last"
        fireOnChange(currInterval, 'MONTHLY', currWeekDays, undefined, undefined, -1)
      }
    },
    // it wants eventStart, which we replace with dtstart and timezone
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [dtstart, timezone, fireOnChange, currInterval, currFreq, currPos]
  )

  const handleIntervalChange = useCallback(
    (
      _event:
        | React.ChangeEvent<HTMLInputElement>
        | React.KeyboardEvent<HTMLInputElement>
        | React.MouseEvent<HTMLButtonElement, MouseEvent>,
      value: string | number
    ) => {
      const num = typeof value === 'string' ? parseInt(value, 10) : value
      if (Number.isNaN(num)) return
      if (num < 1) return
      setCurrInterval(num)
      let monthdate, month
      if (currFreq === 'YEARLY') {
        monthdate = eventStart.date()
        month = eventStart.month() + 1
      }

      fireOnChange(num, currFreq, currWeekDays, monthdate, month, currPos)
    },
    [currFreq, fireOnChange, currWeekDays, currPos, eventStart]
  )

  const handleFreqChange = useCallback(
    (_event, {value}) => {
      activeElement.current = document.activeElement as HTMLElement

      setCurrFreq(value)
      if (value === 'YEARLY') {
        const monthdate = eventStart.date()
        const month = eventStart.month() + 1
        fireOnChange(currInterval, value, undefined, monthdate, month, undefined)
      } else if (value === 'MONTHLY') {
        handleChangeMonthlyMode(_event, {value: currMonthlyMode})
      } else {
        fireOnChange(currInterval, value, currWeekDays, undefined, undefined, undefined)
      }
    },
    [eventStart, fireOnChange, currInterval, handleChangeMonthlyMode, currMonthlyMode, currWeekDays]
  )

  const handleWeekdayChange = useCallback(
    (newSelectedDays: SelectedDaysArray) => {
      setCurrWeekdays(newSelectedDays)
      if (currFreq !== 'WEEKLY') return
      fireOnChange(currInterval, currFreq, newSelectedDays, undefined, undefined, undefined)
    },
    [fireOnChange, currInterval, currFreq]
  )

  const yearlyFreqToText = useCallback(() => {
    return I18n.t('on %{date}', {
      date: new Intl.DateTimeFormat(locale, {
        month: 'long',
        day: 'numeric',
        timeZone: timezone,
      }).format(eventStart.toDate()),
    })
  }, [eventStart, locale, timezone])

  return (
    <div>
      <fieldset style={{borderStyle: 'none', margin: 0, padding: '0'}}>
        <legend style={{marginBottom: '.75rem', borderStyle: 'none'}}>
          <span style={{whiteSpace: 'nowrap'}}>
            <Text weight="bold">{I18n.t('Repeat every:')}</Text>
          </span>
        </legend>
        <div
          style={{
            display: 'flex',
            gap: '.5rem',
            alignItems: 'center',
            justifyContent: 'flex-start',
          }}
        >
          <span style={{flexShrink: 1}}>
            <NumberInput
              data-testid="repeat-interval"
              display="inline-block"
              renderLabel={<ScreenReaderContent>{I18n.t('every')}</ScreenReaderContent>}
              value={interval}
              width={`${px('1em') + px('4rem')}px`}
              onChange={handleIntervalChange}
              onIncrement={event => {
                handleIntervalChange(event, interval + 1)
              }}
              onDecrement={event => {
                handleIntervalChange(event, interval - 1)
              }}
            />
          </span>
          <span style={{minWidth: '7rem', flexShrink: 1}}>
            <SimpleSelect
              data-testid="repeat-frequency"
              inputRef={node => {
                if (node instanceof HTMLInputElement) {
                  freqRef.current = node
                }
              }}
              key={`${interval}-${freq}`}
              renderLabel={<ScreenReaderContent>{I18n.t('frequency')}</ScreenReaderContent>}
              assistiveText={I18n.t('Use arrow keys to navigate options.')}
              value={freq}
              width={freqPickerWidth}
              onChange={handleFreqChange}
            >
              <SimpleSelectOption id="DAILY" value="DAILY">
                {I18n.t('single_and_plural_days', {one: 'Day', other: 'Days'}, {count: interval})}
              </SimpleSelectOption>
              <SimpleSelectOption id="WEEKLY" value="WEEKLY">
                {I18n.t(
                  'single_and_plural_weeks',
                  {one: 'Week', other: 'Weeks'},
                  {count: interval}
                )}
              </SimpleSelectOption>
              <SimpleSelectOption id="MONTHLY" value="MONTHLY">
                {I18n.t(
                  'single_and_plural_months',
                  {one: 'Month', other: 'Months'},
                  {count: interval}
                )}
              </SimpleSelectOption>
              <SimpleSelectOption id="YEARLY" value="YEARLY">
                {I18n.t(
                  'single_and_plural_years',
                  {one: 'Year', other: 'Years'},
                  {count: interval}
                )}
              </SimpleSelectOption>
            </SimpleSelect>
          </span>
          {freq === 'MONTHLY' && (
            <div style={{flexGrow: 1, flexShrink: 0, flexBasis: 'min-content'}}>
              <SimpleSelect
                key={eventStart.toISOString(true)}
                data-testid="repeat-month-mode"
                renderLabel={<ScreenReaderContent>{I18n.t('day of month')}</ScreenReaderContent>}
                assistiveText={I18n.t('Use arrow keys to navigate options.')}
                value={currMonthlyMode}
                width={monthlyOptionsWidth}
                onChange={handleChangeMonthlyMode}
              >
                <SimpleSelectOption id="BYMONTHDATE" value="BYMONTHDATE">
                  {I18n.t('on day %{date}', {date: eventStart.date()})}
                </SimpleSelectOption>
                <SimpleSelectOption id="BYMONTHDAY" value="BYMONTHDAY">
                  {getByMonthdateString(eventStart, locale, timezone)}
                </SimpleSelectOption>
                {isLastWeekdayInMonth(eventStart) && (
                  <SimpleSelectOption id="BYLASTMONTHDAY" value="BYLASTMONTHDAY">
                    {getLastWeekdayInMonthString(getWeekdayName(eventStart, locale, timezone))}
                  </SimpleSelectOption>
                )}
              </SimpleSelect>
            </div>
          )}
          {freq === 'YEARLY' && <Text>{yearlyFreqToText()}</Text>}
        </div>
      </fieldset>
      {freq === 'WEEKLY' && (
        <View as="div" margin="small 0">
          <WeekdayPicker
            data-testid="repeat-weekday"
            locale={locale}
            selectedDays={weekdays || [AllRRULEDayValues[eventStart.day()]]}
            onChange={handleWeekdayChange}
          />
        </View>
      )}
    </div>
  )
}
