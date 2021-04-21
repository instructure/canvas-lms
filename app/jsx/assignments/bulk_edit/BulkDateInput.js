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
import {bool, func, oneOf, string, arrayOf, shape} from 'prop-types'
import tz from 'timezone'
import moment from 'moment-timezone'
import {DateTime} from '@instructure/ui-i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import CanvasDateInput from 'jsx/shared/components/CanvasDateInput'

BulkDateInput.propTypes = {
  label: string.isRequired,
  selectedDateString: string,
  dateKey: oneOf(['due_at', 'unlock_at', 'lock_at']),
  assignmentId: string.isRequired,
  overrideId: string, // may be null
  updateAssignmentDate: func.isRequired,
  timezone: string,
  fancyMidnight: bool,
  interaction: string,
  messages: arrayOf(shape({type: string, text: string}))
}

BulkDateInput.defaultProps = {
  timezone: null,
  fancyMidnight: false,
  interaction: 'enabled'
}

function formatDate(date) {
  return tz.format(date, 'date.formats.medium_with_weekday')
}

function BulkDateInput({
  label,
  selectedDateString,
  messages,
  dateKey,
  assignmentId,
  overrideId,
  updateAssignmentDate,
  timezone,
  fancyMidnight,
  interaction
}) {
  // do this here so tests can modify ENV.TIMEZONE
  timezone = timezone || ENV?.TIMEZONE || DateTime.browserTimeZone()

  const setDate = useCallback(
    newDate => updateAssignmentDate({newDate, dateKey, assignmentId, overrideId}),
    [updateAssignmentDate, dateKey, assignmentId, overrideId]
  )

  const handleSelectedDateChange = useCallback(
    newDate => {
      if (!newDate) {
        setDate(null)
      } else if (selectedDateString) {
        // preserve the existing selected time by adding it to the new date
        const selectedMoment = moment.tz(selectedDateString, timezone)
        const timeOfDayMs = selectedMoment.diff(selectedMoment.clone().startOf('day'))
        const newMoment = moment.tz(newDate, timezone)
        newMoment.add(timeOfDayMs, 'ms')
        setDate(newMoment.toDate())
      } else {
        // assign a default time to the new date
        const newMoment = moment.tz(newDate, timezone)
        if (fancyMidnight) newMoment.endOf('day')
        else newMoment.startOf('day')
        setDate(newMoment.toDate())
      }
    },
    [fancyMidnight, selectedDateString, setDate, timezone]
  )

  const renderLabel = useCallback(() => <ScreenReaderContent>{label}</ScreenReaderContent>, [label])

  const selectedDate = tz.parse(selectedDateString)
  return (
    <CanvasDateInput
      renderLabel={renderLabel}
      selectedDate={selectedDate}
      formatDate={formatDate}
      onSelectedDateChange={handleSelectedDateChange}
      timezone={timezone}
      interaction={interaction}
      messages={messages}
    />
  )
}

export default React.memo(BulkDateInput)
