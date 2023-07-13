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
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CustomRecurrenceModal, {CustomRecurrenceModalProps} from './CustomRecurrenceModal'
import {ISODateToIcalDate} from '../RRuleHelper'
import RRuleToNaturalLanguage from '../RRuleNaturalLanguage'

export default {
  title: 'Examples/Calendar/RecurringEvents/CustomRecurrenceModal',
  component: CustomRecurrenceModal,
} as Meta

const Template: Story<CustomRecurrenceModalProps> = args => {
  const {RRULE = ''} = args
  const [currRRULE, setCurrRRULE] = useState<string>(RRULE)
  const [isModalOpen, setIsModalOpen] = useState<boolean>(true)

  const handleChange = useCallback((newRRULE: string | null) => {
    setCurrRRULE(newRRULE)
    setIsModalOpen(false)
  }, [])

  const handleDismiss = useCallback(() => {
    setIsModalOpen(false)
  }, [])

  const handleClose = useCallback(() => {}, [])

  return (
    <div style={{maxWidth: '700px'}}>
      <View as="div" margin="small">
        <Button onClick={() => setIsModalOpen(true)}>Open Modal</Button>
      </View>
      <CustomRecurrenceModal
        eventStart={args.eventStart}
        locale={args.locale}
        timezone={args.timezone}
        courseEndAt={args.courseEndAt}
        RRULE={currRRULE}
        isOpen={isModalOpen}
        onClose={handleClose}
        onDismiss={handleDismiss}
        onSave={handleChange}
      />
      <div style={{margin: '.75rem 0', lineHeight: 1.5}}>
        <Text as="div">eventStart: {args.eventStart}</Text>
        <Text as="div">result: {currRRULE}</Text>
        <Text as="div">{RRuleToNaturalLanguage(currRRULE, args.locale, args.timezone)}</Text>
      </div>
    </div>
  )
}

const mytimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

export const Default = Template.bind({})
const defaultEventStart = moment.tz('2023-07-04', mytimezone)

Default.args = {
  eventStart: moment().tz(mytimezone).toISOString(true),
  locale: 'en',
  timezone: mytimezone,
  RRULE: '',
}

// event starts on july 4, but the rrule says repeat every feb 7
export const OutOfSyncEventStart = Template.bind({})
OutOfSyncEventStart.args = {
  eventStart: moment.tz('2023-07-04', mytimezone).toISOString(true),
  locale: 'en',
  timezone: mytimezone,
  RRULE: 'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=7;COUNT=3',
}

export const WithCourseEnd = Template.bind({})
WithCourseEnd.args = {
  locale: 'en',
  timezone: mytimezone,
  RRULE: 'FREQ=DAILY;INTERVAL=1;COUNT=3',
  eventStart: moment.tz(mytimezone).toISOString(true),
  courseEndAt: moment.tz(mytimezone).add(18, 'months').toISOString(true),
}

export const YearlyJuly4 = Template.bind({})
YearlyJuly4.args = {
  local: 'en',
  timezone: mytimezone,
  eventStart: moment.tz('2023-07-04', mytimezone).toISOString(true),
  // RRULE: 'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=1;UNTIL=20240501T000000Z',
  // RRULE: 'FREQ=MONTHLY;BYSETPOS=1;BYDAY=MO;INTERVAL=1;UNTIL=20240501T000000Z', // monthly on the first Monday
  // RRULE: 'FREQ=MONTHLY;BYMONTHDAY=2;INTERVAL=1;UNTIL=20240501T000000Z', // monthly on the 2nd of the month
  RRULE: `FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=4;UNTIL=${ISODateToIcalDate(
    defaultEventStart.clone().add(5, 'years').toISOString(true)
  )}`,
}
