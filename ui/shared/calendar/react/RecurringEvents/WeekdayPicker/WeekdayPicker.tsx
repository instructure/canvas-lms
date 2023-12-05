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

/**
 * WeekdayPicker is a component for selecting days of the week.
 * As the user clicks on the days, the selected days are highlighted
 * and onChange is called with the selected days. The selected days
 * are represented as an array of RRULE day values. (e.g. SU, MO, TU, etc.)
 * and are sorted in the order of the locale's first day of week.
 */

import React, {useCallback, useEffect, useRef, useState} from 'react'
import moment from 'moment'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope} from '@canvas/i18n'

import type {RRULEDayValue, SelectedDaysArray} from '../types'

const I18n = useScope('calendar_custom_recurring_event_weekday_picker')

export type WeekArray = [string, string, string, string, string, string, string]
export type WeekDaysSpec = {
  dayNames: WeekArray
  dayAbbreviations: WeekArray
  dayRRULEValues: WeekArray
}

export type OnDaysChange = (selectedDays: SelectedDaysArray) => void

export type WeekdayPickerProps = {
  readonly selectedDays?: SelectedDaysArray
  readonly onChange: OnDaysChange
  readonly locale: string
}

const defaultWeekDayAbbreviations = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']

export default function WeekdayPicker({locale, selectedDays = [], onChange}: WeekdayPickerProps) {
  const [weekDays, setWeekDays] = useState<WeekDaysSpec>({
    dayNames: [
      I18n.t('Sunday'),
      I18n.t('Monday'),
      I18n.t('Tuesday'),
      I18n.t('Wednesday'),
      I18n.t('Thursday'),
      I18n.t('Friday'),
      I18n.t('Saturday'),
    ],
    dayAbbreviations:
      I18n.lookup('date.datepicker.column_headings', {locale}) || defaultWeekDayAbbreviations,
    dayRRULEValues: ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'],
  })
  const localeRef = useRef<string>(locale)
  const [firstDayOfWeek] = useState<number>(moment.localeData(locale).firstDayOfWeek())

  useEffect(() => {
    if (locale !== localeRef.current) {
      throw new Error('locale prop cannot be changed after initial render')
    }
  }, [locale])

  useEffect(() => {
    setWeekDays(prevWeekDays => {
      const newWeekdays: WeekDaysSpec = {
        dayNames: [...prevWeekDays.dayNames],
        dayAbbreviations: [...prevWeekDays.dayAbbreviations],
        dayRRULEValues: [...prevWeekDays.dayRRULEValues],
      }
      for (let i = 0; i < firstDayOfWeek; ++i) {
        newWeekdays.dayNames.push(newWeekdays.dayNames.shift() as string)
        newWeekdays.dayAbbreviations.push(newWeekdays.dayAbbreviations.shift() as string)
        newWeekdays.dayRRULEValues.push(newWeekdays.dayRRULEValues.shift() as string)
      }
      return newWeekdays
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleDayChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const day = e.target.value
      const checked = e.target.checked
      const newDays: SelectedDaysArray = [...selectedDays]
      if (checked && !selectedDays.includes(day as RRULEDayValue)) {
        newDays.push(day as RRULEDayValue)
      } else if (!checked) {
        const index = selectedDays.indexOf(day as RRULEDayValue)
        if (index !== -1) {
          newDays.splice(index, 1)
        }
      }
      const sortedDays = newDays.sort(
        (a, b) => weekDays.dayRRULEValues.indexOf(a) - weekDays.dayRRULEValues.indexOf(b)
      )
      onChange(sortedDays)
    },
    [onChange, selectedDays, weekDays.dayRRULEValues]
  )

  // until canvas is on instui 8 where <Flex> has the gap prop
  const flexStyle = {
    display: 'flex',
    gap: '.5rem',
  }

  return (
    <FormFieldGroup description={I18n.t('Repeats on:')} layout="columns">
      <div style={flexStyle}>
        {weekDays.dayRRULEValues.map((d, i) => {
          const checked = selectedDays.includes(d as RRULEDayValue)
          return (
            <OneDay
              key={d}
              label={weekDays.dayAbbreviations[i]}
              screenreaderLabel={weekDays.dayNames[i]}
              value={d}
              checked={checked}
              onChange={handleDayChange}
            />
          )
        })}
      </div>
    </FormFieldGroup>
  )
}

export type OneDayProps = {
  readonly label: string
  readonly screenreaderLabel: string
  readonly value: string
  readonly checked: boolean
  readonly onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
}

export function OneDay({label, screenreaderLabel, value, checked, onChange}: OneDayProps) {
  const id = label.replaceAll(/\s/g, '')
  const bgcolor = checked ? 'brand' : 'secondary'

  const [focused, setFocused] = useState<boolean>(false)

  return (
    // it does by virtue of wrapping it
    // eslint-disable-next-line jsx-a11y/label-has-associated-control
    <label>
      <View
        as="div"
        background={bgcolor}
        borderRadius="pill"
        display="flex"
        margin="0"
        minHeight="3rem"
        minWidth="3rem"
        padding="small"
        position="relative"
        withFocusOutline={focused}
      >
        <input
          id={id}
          value={value}
          type="checkbox"
          style={{opacity: 0.0001, position: 'absolute', left: 0, top: 0, pointerEvents: 'none'}}
          checked={checked}
          aria-checked={checked}
          onChange={onChange}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
        />
        <span style={{margin: '0 auto'}}>
          <AccessibleContent alt={screenreaderLabel}>
            <Text color={checked ? 'primary-inverse' : 'primary'}>{label}</Text>
          </AccessibleContent>
        </span>
      </View>
    </label>
  )
}
