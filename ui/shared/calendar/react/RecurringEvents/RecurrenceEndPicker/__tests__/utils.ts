/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {act, fireEvent, screen, waitFor} from '@testing-library/react'
import moment from 'moment-timezone'

export function formatDate(date: Date, locale: string, timezone: string) {
  return new Intl.DateTimeFormat('en', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    timeZone: timezone,
  }).format(date)
}

export function makeSimpleIsoDate(date: moment.Moment): string {
  return date.format('YYYY-MM-DDTHH:mm:ssZ')
}

export async function changeUntilDate(
  enddate: moment.Moment,
  newenddate: moment.Moment,
  locale: string,
  timezone: string
) {
  const displayedUntil = formatDate(enddate.toDate(), locale, timezone)
  const dateinput = screen.getByDisplayValue(displayedUntil)
  const newEndDateStr = formatDate(newenddate.toDate(), locale, timezone)
  act(() => {
    fireEvent.change(dateinput, {target: {value: newEndDateStr}})
  })
  await waitFor(() => screen.getByDisplayValue(newEndDateStr))
  act(() => {
    fireEvent.blur(dateinput)
  })
}
