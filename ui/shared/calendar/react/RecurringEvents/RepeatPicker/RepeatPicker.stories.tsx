// @ts-nocheck
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

import React, {useCallback, useState} from 'react'
import moment from 'moment-timezone'
import {Story, Meta} from '@storybook/react'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import RepeatPicker, {OnRepeatPickerChangeType} from './RepeatPicker'
import {SelectedDaysArray} from '../WeekdayPicker/WeekdayPicker'

export default {
  title: 'Examples/Calendar/RecurringEvents/RepeatPicker',
  component: RepeatPicker,
} as Meta

const Template: Story<RepeatPicker> = args => {
  const [interval, setInterval] = useState<Number>(args.interval)
  const [freq, setFreq] = useState(args.freq)
  const [weekdays, setWeekdays] = useState<SelectedDaysArray | undefined>(args.weekdays)
  const [monthdate, setMonthdate] = useState<Number | undefined>(args.monthdate)
  const [pos, setPos] = useState<number | undefined>(null)

  const handleChange = useCallback((newVal: OnRepeatPickerChangeType): void => {
    setInterval(newVal.interval)
    setFreq(newVal.freq)
    setWeekdays(newVal.weekdays)
    setMonthdate(newVal.monthdate)
    setPos(newVal.pos)
  }, [])

  return (
    <div style={{maxWidth: '700px'}}>
      <style>
        button:focus {'{'} outline: 2px solid dodgerblue; {'}'}
      </style>
      <button type="button" onClick={e => e.target.focus()}>
        tab stop before
      </button>
      <View as="div" margin="small">
        <RepeatPicker
          locale={args.locale}
          timezone={args.timezone}
          dtstart={args.dtstart}
          interval={interval}
          freq={freq}
          weekdays={weekdays}
          monthdate={monthdate}
          pos={pos}
          onChange={handleChange}
        />
      </View>
      <button type="button" onClick={e => e.target.focus()}>
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
        <Text as="div">{`interval: ${interval}`}</Text>
        <Text as="div">{`freq: ${freq}`}</Text>
        <Text as="div">{`weekdays: ${weekdays}`}</Text>
        <Text as="div">{`monthdate: ${monthdate}`}</Text>
        <Text as="div">{`pos: ${pos}`}</Text>
      </div>
    </div>
  )
}

const TZ = Intl.DateTimeFormat().resolvedOptions().timeZone

export const Default = Template.bind({})
Default.args = {
  locale: 'en',
  timezone: TZ,
  dtstart: moment().tz(TZ).format('YYYY-MM-DD'),
  interval: 2,
  freq: 'DAILY',
}

export const ADifferentStart = Template.bind({})
ADifferentStart.args = {
  locale: 'en',
  timezone: TZ,
  dtstart: moment().tz(TZ).add(17, 'days').format('YYYY-MM-DD'),
  interval: 2,
  freq: 'MONTHLY',
}
