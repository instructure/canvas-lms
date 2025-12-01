/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import useDateTimeFormat from '@canvas/use-date-time-format-hook'

export const useDateFormatPattern = (): string => {
  const compactDateFormatter = useDateTimeFormat('date.formats.compact')

  const year = 2025
  const month = 10 // november (0-indexed)
  const day = 28

  const date = new Date(Date.UTC(year, month, day, 12, 0, 0))
  const dateFormat = compactDateFormatter(date)

  const numbers = dateFormat.match(/\d+/g)

  if (!numbers || numbers.length < 3) {
    return 'MM/DD/YYYY'
  }

  const yearString = numbers.find(n => n.length === 4) || year.toString()
  const monthString = numbers.find(n => n === '11') || (month + 1).toString()
  const dayString = numbers.find(n => n === '28') || day.toString()

  return dateFormat.replace(yearString, 'YYYY').replace(dayString, 'DD').replace(monthString, 'MM')
}
