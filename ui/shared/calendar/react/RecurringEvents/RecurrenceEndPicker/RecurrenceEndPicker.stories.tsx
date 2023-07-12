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
import RecurrenceEndPicker, {OnRecurrenceEndChangeType} from './RecurrenceEndPicker'

export default {
  title: 'Examples/Calendar/RecurringEvents/RecurrenceEndPicker',
  component: RecurrenceEndPicker,
} as Meta

const Template: Story<RecurrenceEndPicker> = args => {
  const {until, count} = args
  const [currUntil, setCurrUntil] = useState(until)
  const [currCount, setCurrCount] = useState(count)

  const handleChange = useCallback((newVal: OnRecurrenceEndChangeType): void => {
    setCurrUntil(newVal.until)
    setCurrCount(newVal.count)
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
        <RecurrenceEndPicker
          courseEndAt={args.courseEndAt}
          dtstart={args.dtstart}
          locale={args.locale}
          timezone={args.timezone}
          freq={args.freq}
          interval={args.interval}
          until={currUntil}
          count={currCount}
          onChange={handleChange}
        />
      </View>
      <button type="button" onClick={e => e.target.focus()}>
        tab stop after
      </button>
      <div style={{margin: '.75rem 0', lineHeight: 1.5}}>
        <Text as="div">{`until: ${moment.tz(currUntil, args.timezone).toISOString(true)}`}</Text>
        <Text as="div">{`count: ${currCount}`}</Text>
      </div>
    </div>
  )
}

const mytimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

export const Default = Template.bind({})
Default.args = {
  locale: 'en',
  timezone: mytimezone,
  freq: 'DAILY',
}

export const WithCount = Template.bind({})
WithCount.args = {
  locale: 'en',
  timezone: mytimezone,
  count: 2,
  freq: 'DAILY',
  interval: 2,
}

export const WithUntil = Template.bind({})
WithUntil.args = {
  locale: 'en',
  timezone: 'America/Los_Angeles',
  until: '2024-06-30',
  freq: 'DAILY',
  interval: 2,
}

export const InGerman = Template.bind({})
InGerman.args = {
  locale: 'de',
  timezone: mytimezone,
  until: '2024-06-30',
  freq: 'DAILY',
  interval: 2,
}

export const CourseEnds = Template.bind({})
CourseEnds.args = {
  locale: 'en',
  timezone: mytimezone,
  courseEndAt: '2024-06-30',
  freq: 'DAILY',
  interval: 2,
}
