//
// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import moment from 'moment-timezone'
import type {MomentInput} from 'moment-timezone'

export function isoDateFromInput(
  dateType: 'start-date' | 'end-date',
  input: MomentInput,
  timezone?: string
) {
  if (!input) return undefined

  let date = moment(input)
  if (timezone) {
    date = date.tz(timezone)
  }
  const shiftedDate = dateType === 'end-date' ? date.endOf('day') : date.startOf('day')
  return shiftedDate.toISOString()
}
