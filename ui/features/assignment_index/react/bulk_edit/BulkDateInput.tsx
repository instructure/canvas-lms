/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useCallback} from 'react'
import moment from 'moment-timezone'
import {View} from '@instructure/ui-view'
import {DateTime} from '@instructure/ui-i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import type {FormMessage} from '@instructure/ui-form-field'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

interface BulkDateInputProps {
  label: string
  selectedDateString?: string
  dateKey: 'due_at' | 'unlock_at' | 'lock_at'
  assignmentId: string
  overrideId?: string
  updateAssignmentDate: (params: {
    newDate: Date | null
    dateKey: string
    assignmentId: string
    overrideId?: string
  }) => void
  timezone?: string | null
  fancyMidnight?: boolean
  defaultTime?: string | null
  interaction?: 'disabled' | 'enabled' | 'readonly'
  messages?: FormMessage[]
  width?: string
}

function BulkDateInput({
  label,
  selectedDateString,
  messages,
  dateKey,
  assignmentId,
  overrideId,
  updateAssignmentDate,
  timezone = null,
  fancyMidnight = false,
  defaultTime = null,
  interaction = 'enabled',
  width = '100%',
}: BulkDateInputProps) {
  // do this here so tests can modify ENV.TIMEZONE
  timezone = timezone || ENV?.TIMEZONE || DateTime.browserTimeZone()

  const formatDate = useDateTimeFormat('date.formats.full_with_weekday', timezone)

  const setDate = useCallback(
    (newDate: Date | null) => updateAssignmentDate({newDate, dateKey, assignmentId, overrideId}),
    [updateAssignmentDate, dateKey, assignmentId, overrideId],
  )

  const handleSelectedDateChange = useCallback(
    (newDate: Date | null, dateInputType?: string) => {
      if (!newDate) {
        setDate(null)
      } else if (dateInputType === 'pick' && selectedDateString) {
        // preserve the existing selected time when picking date from the calendar and there is an already existing date in the textbox
        const selectedMoment = moment.tz(selectedDateString, timezone)
        const newMoment = moment.tz(newDate, timezone)
        const [h, m, s, ms] = [
          selectedMoment.hour(),
          selectedMoment.minute(),
          selectedMoment.second(),
          selectedMoment.millisecond(),
        ]
        newMoment.hour(h)
        newMoment.minute(m)
        newMoment.second(s)
        newMoment.millisecond(ms)
        setDate(newMoment.toDate())
      } else {
        const newMoment = moment.tz(newDate, timezone)
        const isMidnight =
          newMoment.hour() === 0 && newMoment.minute() === 0 && newMoment.second() === 0
        if (isMidnight) {
          // Only applys the default time or fancy midnight if user picked date from the calendar or typed a string without time (HH:ss).
          // This prevents the update when the user manually updates the time (HH:ss).
          if (defaultTime) {
            const [h, m, s] = defaultTime.split(':').map(n => parseInt(n, 10))
            newMoment.hour(h)
            newMoment.minute(m)
            newMoment.second(s)
          } else if (fancyMidnight) {
            newMoment.endOf('day')
          }
        }
        setDate(newMoment.toDate())
      }
    },
    [fancyMidnight, defaultTime, selectedDateString, setDate, timezone],
  )

  const renderLabel = useCallback(
    () => <ScreenReaderContent>{label}</ScreenReaderContent>,
    [label],
  ) as any

  return (
    <View as="div" minWidth={width} margin="x-small 0">
      <CanvasDateInput2
        renderLabel={renderLabel}
        selectedDate={selectedDateString}
        formatDate={formatDate}
        onSelectedDateChange={handleSelectedDateChange}
        timezone={timezone}
        interaction={interaction}
        messages={messages}
        width={width}
        withRunningValue={true}
      />
    </View>
  )
}

export default React.memo(BulkDateInput)
