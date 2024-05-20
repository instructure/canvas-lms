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

import React, {useCallback, useEffect, useState} from 'react'
// I don't know why, but this import creates a tsc error in jenkins
// saying @storybook/react cannot be found, even though it's ok locally.
// @ts-ignore
import {Story, Meta} from '@storybook/react'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasDateInput, {type CanvasDateInputProps} from './DateInput'
import type {FormMessage} from '@instructure/ui-form-field'

export default {
  title: 'Examples/Shared/Date and Time Helpers/CanvasDateInput',
  component: CanvasDateInput,
} as Meta

export type UnknownSubset<T> = {
  [K in keyof T]?: T[K]
}

const Template: Story<typeof CanvasDateInput> = (args: UnknownSubset<CanvasDateInputProps>) => {
  const [dateFormatterError, setDateFormatterError] = useState<Error | null>(null)

  const createDateFormatter = useCallback((locale_: string, timezone_: string) => {
    try {
      const formatter = new Intl.DateTimeFormat(locale_, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        timeZone: timezone_,
      }).format

      const safeFormatter = (date_: Date): string => {
        try {
          return formatter(date_)
        } catch (e) {
          setDateFormatterError(e as Error)
          return ''
        }
      }
      return safeFormatter
    } catch (e) {
      setDateFormatterError(e as Error)
      return (date_: Date) => date_.toISOString()
    }
  }, [])

  const [locale, setLocale] = useState(args.locale || 'en')
  const [timezone, setTimezone] = useState(args.timezone || 'UTC')
  const [date, setDate] = useState<Date | null>(
    args.selectedDate ? new Date(args.selectedDate) : null
  )

  const [messages] = useState<FormMessage[]>([
    {type: 'hint', text: "Default date will be today's date"},
  ])
  const [dateFormatter, setDateFormatter] = useState<(date: Date) => string>(() =>
    createDateFormatter(locale, timezone)
  )

  useEffect(() => {
    if (args.locale !== locale) {
      setLocale(args.locale || 'en')
    }
  }, [args.locale, locale])

  useEffect(() => {
    if (args.timezone !== timezone) {
      setTimezone(args.timezone || 'UTC')
    }
  }, [args.timezone, timezone])

  useEffect(() => {
    const newformatter = createDateFormatter(locale, timezone)
    setDateFormatter(() => newformatter)
  }, [createDateFormatter, locale, timezone])

  useEffect(() => {
    setDate(args.selectedDate ? new Date(args.selectedDate) : null)
  }, [args.selectedDate])

  const handleDateChange = useCallback(
    (newDate: Date | null, mode: 'pick' | 'other' | 'error'): void => {
      if (mode === 'error') {
        setDate(null)
        setDateFormatterError(new Error('Invalid date'))
      } else {
        setDate(newDate)
        setDateFormatterError(null)
      }
    },
    []
  )

  return (
    <div style={{maxWidth: '700px'}}>
      <style>
        button:focus {'{'} outline: 2px solid dodgerblue; {'}'}
      </style>
      <button type="button" onClick={e => (e.target as HTMLButtonElement).focus()}>
        tab stop before
      </button>
      <View as="div" margin="small">
        <CanvasDateInput
          renderLabel="Date"
          selectedDate={date?.toISOString()}
          formatDate={dateFormatter}
          interaction="enabled"
          onSelectedDateChange={handleDateChange}
          width="15rem"
          display="block"
          timezone={timezone}
          messages={messages}
          withRunningValue={true}
          defaultToToday={args.defaultToToday}
        />
      </View>
      <button type="button" onClick={e => (e.target as HTMLButtonElement).focus()}>
        tab stop after
      </button>
      <div
        style={{
          margin: '.75rem 0',
          lineHeight: 1.5,
          paddingTop: '.75rem',
          borderTop: '1px solid grey',
        }}
      >
        <Text as="div">{date ? dateFormatter(date) : '** no date **'}</Text>
        {dateFormatterError && (
          <Text as="div" color="alert">
            {dateFormatterError.message}
          </Text>
        )}
      </div>
    </div>
  )
}

export const Default = Template.bind({})
Default.args = {
  locale: 'en-US',
  timezone: 'America/New_York',
  selectedDate: '2021-06-01',
  defaultToToday: false,
}
