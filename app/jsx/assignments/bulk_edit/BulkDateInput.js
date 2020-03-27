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

import React from 'react'
import {bool, func, instanceOf, string} from 'prop-types'
import tz from 'timezone'
import moment from 'moment-timezone'
import {DateTime} from '@instructure/ui-i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import CanvasDateInput from 'jsx/shared/components/CanvasDateInput'

BulkDateInput.propTypes = {
  label: string.isRequired,
  selectedDate: instanceOf(Date),
  onSelectedDateChange: func.isRequired,
  timezone: string,
  fancyMidnight: bool
}

BulkDateInput.defaultProps = {
  timezone: null,
  fancyMidnight: false
}

export default function BulkDateInput({
  label,
  selectedDate,
  onSelectedDateChange,
  timezone,
  fancyMidnight
}) {
  // do this here so tests can modify ENV.TIMEZONE
  timezone = timezone || ENV?.TIMEZONE || DateTime.browserTimeZone()

  function formatDate(date) {
    return tz.format(date, 'date.formats.medium_with_weekday')
  }

  function handleSelectedDateChange(newDate) {
    if (!newDate) {
      onSelectedDateChange(null)
    } else if (selectedDate) {
      // preserve the existing selected time by adding it to the new date
      const selectedMoment = moment.tz(selectedDate, timezone)
      const timeOfDayMs = selectedMoment.diff(selectedMoment.clone().startOf('day'))
      const newMoment = moment.tz(newDate, timezone)
      newMoment.add(timeOfDayMs, 'ms')
      onSelectedDateChange(newMoment.toDate())
    } else {
      // assign a default time to the new date
      const newMoment = moment.tz(newDate, timezone)
      if (fancyMidnight) newMoment.endOf('day')
      else newMoment.startOf('day')
      onSelectedDateChange(newMoment.toDate())
    }
  }

  return (
    <CanvasDateInput
      renderLabel={<ScreenReaderContent>{label}</ScreenReaderContent>}
      selectedDate={selectedDate}
      formatDate={formatDate}
      onSelectedDateChange={handleSelectedDateChange}
      timezone={timezone}
    />
  )
}
