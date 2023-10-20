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

import React, {useCallback, useEffect, useState} from 'react'
import {Story, Meta} from '@storybook/react'
import moment from 'moment-timezone'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CustomRecurrence, {CustomRecurrenceProps} from './CustomRecurrence'
import RRuleHelper, {RRuleHelperSpec, ISODateToIcalDate} from '../RRuleHelper'

export default {
  title: 'Examples/Calendar/RecurringEvents/CustomRecurrence',
  component: CustomRecurrence,
} as Meta

const specToRule = (spec: RRuleHelperSpec): string => {
  try {
    const rrule = new RRuleHelper(spec)
    return rrule.toString()
  } catch (e) {
    return e.message
  }
}

const makeValidEventStart = (eventStart: string, timezone: string): string => {
  const es = !eventStart ? moment().tz(timezone) : moment.tz(eventStart, timezone)
  if (es.isValid()) return es.format('YYYY-MM-DDTHH:mm:ssZ')
  return moment().tz(timezone).format('YYYY-MM-DDTHH:mm:ssZ')
}

const Template: Story<CustomRecurrenceProps> = args => {
  const {RRULE = '', eventStart, timezone, locale} = args
  const [currRRULESpec, setCurrRRULESpec] = useState<RRuleHelperSpec>(
    new RRuleHelper(RRuleHelper.parseString(RRULE)).spec
  )
  const [currEventStart, setCurrEventStart] = useState<string>(() => {
    return makeValidEventStart(eventStart, timezone)
  })

  useEffect(() => {
    setCurrEventStart(makeValidEventStart(eventStart, timezone))
  }, [timezone, eventStart])

  useEffect(() => {
    setCurrRRULESpec(new RRuleHelper(RRuleHelper.parseString(RRULE)).spec)
  }, [RRULE])

  const handleChange = useCallback((newSpec: RRuleHelperSpec) => {
    setCurrRRULESpec(newSpec)
  }, [])

  return (
    <div style={{maxWidth: '700px'}}>
      <style>
        button:focus {'{'} outline: 2px solid dodgerblue; {'}'}
      </style>
      <button type="button" onClick={e => e.target.focus()}>
        tab stop before
      </button>
      <View as="div" margin="small" width="50%">
        <CustomRecurrence
          eventStart={currEventStart}
          locale={locale}
          timezone={timezone}
          rruleSpec={currRRULESpec}
          onChange={handleChange}
        />
      </View>
      <button type="button" onClick={e => e.target.focus()}>
        tab stop after
      </button>
      <div style={{margin: '.75rem 0', lineHeight: 1.5}}>
        <Text as="div">eventStart: {currEventStart}</Text>
        <Text as="div">result: {specToRule(currRRULESpec)}</Text>
      </div>
    </div>
  )
}

const mytimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

export const Default = Template.bind({})
Default.args = {
  locale: 'en',
  timezone: mytimezone,
  // RRULE: 'FREQ=DAILY;INTERVAL=1;COUNT=3',
  // RRULE: 'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=1;UNTIL=20240501T000000Z',
  // RRULE: 'FREQ=MONTHLY;BYSETPOS=1;BYDAY=MO;INTERVAL=1;UNTIL=20240501T000000Z', // monthly on the first Monday
  // RRULE: 'FREQ=MONTHLY;BYMONTHDAY=2;INTERVAL=1;UNTIL=20240501T000000Z', // monthly on the 2nd of the month
  RRULE: 'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=7;COUNT=4', // yearly on Feb 7
}

export const InGBEnglish = Template.bind({})
InGBEnglish.args = {
  locale: 'en-GB',
  timezone: mytimezone,
  RRULE: 'FREQ=DAILY;INTERVAL=1;COUNT=3',
}

export const WithEventStart = Template.bind({})
WithEventStart.args = {
  locale: 'en',
  timezone: 'America/Los_Angeles',
  eventStart: moment().tz('America/Los_Angeles').add(-1, 'month').toISOString(true),
  RRULE: '',
}

const untilTheFuture = ISODateToIcalDate(moment().tz(mytimezone).add(9, 'months').toISOString(true))
export const InitWithUntil = Template.bind({})
InitWithUntil.args = {
  locale: 'en',
  timezone: mytimezone,
  RRULE: `FREQ=MONTHLY;BYMONTHDAY=1;INTERVAL=1;UNTIL=${untilTheFuture}`,
}

export const WithNoRRULE = Template.bind({})
WithNoRRULE.args = {
  local: 'en',
  timezone: mytimezone,
  RRULE: '',
}
