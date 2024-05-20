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
import type {FrequencyValue, RRULEDayValue, UnknownSubset} from '../types'
import RRuleHelper, {type RRuleHelperSpec, RruleValidationError} from '../RRuleHelper'
import RepeatPicker, {type OnRepeatPickerChangeType} from '../RepeatPicker/RepeatPicker'
import RecurrenceEndPicker, {
  type OnRecurrenceEndChangeType,
} from '../RecurrenceEndPicker/RecurrenceEndPicker'
import {View} from '@instructure/ui-view'

export type CustomRecurrenceProps = {
  locale: string
  timezone: string
  eventStart: string
  courseEndAt?: string
  rruleSpec: RRuleHelperSpec
  onChange: (newSpec: RRuleHelperSpec) => void
}

type RRULESpecOverride = UnknownSubset<RRuleHelperSpec>

type StateToSpecFunc = (overrides: RRULESpecOverride) => RRuleHelperSpec

function startToString(dtstart: string | null, timezone: string): string {
  const start = dtstart == null ? moment().tz(timezone) : moment.tz(dtstart, timezone)
  if (start.isValid()) return start.format('YYYY-MM-DDTHH:mm:ssZ')
  throw new RruleValidationError('eventStart is not a valid date')
}

// NOTE: you can get some weird results if the rrule isn't in sync with the eventStart
// For example, event start is on July 4, but the rrule says
// FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=7 (i.e. Feb 7)
export default function CustomRecurrence({
  locale,
  timezone,
  eventStart,
  courseEndAt,
  rruleSpec,
  onChange,
}: CustomRecurrenceProps) {
  const [rrule_obj, set_rrule_obj] = useState(new RRuleHelper(rruleSpec))

  const [freq, setFreq] = useState<FrequencyValue>(rrule_obj.spec.freq)
  const [interval, setInterval] = useState<number>(rrule_obj.spec.interval)
  const [weekdays, setWeekdays] = useState<RRULEDayValue[] | undefined>(rrule_obj.spec.weekdays)
  const [month, setMonth] = useState<number | undefined>(rrule_obj.spec.month)
  const [monthdate, setMonthdate] = useState<number | undefined>(rrule_obj.spec.monthdate)
  const [pos, setPos] = useState<number | undefined>(rrule_obj.spec.pos)
  const [count, setCount] = useState<number | undefined>(rrule_obj.spec.count)
  const [until, setUntil] = useState<string | undefined>(rrule_obj.spec.until)
  const [dtstart_str, setDtstartStr] = useState<string>(startToString(eventStart, timezone))

  const stateToSpec = useCallback<StateToSpecFunc>(
    (overrides: RRULESpecOverride) => {
      const currSpec = {
        freq,
        interval,
        weekdays,
        monthdate,
        pos,
        month,
        count,
        until,
      }
      return new RRuleHelper({...currSpec, ...overrides}).spec
    },
    [count, freq, interval, month, monthdate, pos, until, weekdays]
  )

  const fireOnChange = useCallback(
    (spec: RRuleHelperSpec) => {
      onChange(spec)
    },
    [onChange]
  )

  useEffect(() => {
    const eventStartMoment = moment(eventStart)
    if (!eventStartMoment.isValid()) {
      throw new RruleValidationError('eventStart is not a valid date')
    }
    setDtstartStr(startToString(eventStart, timezone))
    let updatedSpec
    if (typeof rrule_obj.spec.month === 'number') {
      if (eventStartMoment.month() + 1 !== rrule_obj.spec.month) {
        updatedSpec = {...rrule_obj.spec, month: eventStartMoment.month() + 1}
        setMonth(updatedSpec.month)
      }
      if (eventStartMoment.date() !== rrule_obj.spec.monthdate) {
        updatedSpec = updatedSpec || {...rrule_obj.spec}
        updatedSpec.monthdate = eventStartMoment.date()
        setMonthdate(updatedSpec.monthdate)
      }
    }
    if (updatedSpec) {
      fireOnChange(updatedSpec)
    }
  }, [eventStart, fireOnChange, rrule_obj.spec, timezone])

  useEffect(() => {
    set_rrule_obj(new RRuleHelper(rruleSpec))
  }, [rruleSpec])

  useEffect(() => {
    setFreq(rrule_obj.spec.freq)
    setInterval(rrule_obj.spec.interval)
    setWeekdays(rrule_obj.spec.weekdays)
    setMonthdate(rrule_obj.spec.monthdate)
    setMonth(rrule_obj.spec.month)
    setPos(rrule_obj.spec.pos)
    setDtstartStr(startToString(dtstart_str, timezone))
    setCount(rrule_obj.spec.count)
    setUntil(rrule_obj.spec.until)
  }, [dtstart_str, rrule_obj, timezone])

  const handleFrequencyChange = useCallback(
    (newFreqSpec: OnRepeatPickerChangeType) => {
      setFreq(newFreqSpec.freq)
      setInterval(newFreqSpec.interval)
      setWeekdays(newFreqSpec.weekdays)
      setMonthdate(newFreqSpec.monthdate)
      setPos(newFreqSpec.pos)
      fireOnChange(stateToSpec(newFreqSpec))
    },
    [fireOnChange, stateToSpec]
  )

  const handleEndChange = useCallback(
    (endspec: OnRecurrenceEndChangeType) => {
      setCount(endspec.count)
      setUntil(endspec.until)
      fireOnChange(stateToSpec({count: endspec.count, until: endspec.until}))
    },
    [fireOnChange, stateToSpec]
  )

  return (
    <View as="div" data-testid="custom-recurrence">
      <View as="div" margin="small 0">
        <RepeatPicker
          locale={locale}
          timezone={timezone}
          dtstart={dtstart_str}
          interval={interval}
          freq={freq}
          weekdays={weekdays}
          pos={pos}
          onChange={handleFrequencyChange}
        />
      </View>
      <View as="div" margin="small 0">
        <RecurrenceEndPicker
          dtstart={dtstart_str}
          locale={locale}
          timezone={timezone}
          freq={freq}
          interval={interval}
          until={until}
          count={count}
          courseEndAt={courseEndAt}
          onChange={handleEndChange}
        />
      </View>
    </View>
  )
}
