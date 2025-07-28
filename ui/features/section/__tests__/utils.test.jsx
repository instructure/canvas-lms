/* Copyright (C) 2025 - present Instructure, Inc.
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

import {
  generateMessages,
  validateDateTime,
  validateStartDateAfterEnd,
  START_AT_DATE,
  END_AT_DATE,
} from '../utils'

const mockENV = {
  CONTEXT_TIMEZONE: 'America/New_York',
  TIMEZONE: 'America/Los_Angeles',
  context_asset_string: 'course_123',
}

beforeEach(() => {
  global.ENV = {...mockENV}
  jest.clearAllMocks()
})

describe('generateMessages', () => {
  it('returns error message when error is true', () => {
    const result = generateMessages(null, true, 'any message')
    expect(result).toEqual([
      {
        type: 'newError',
        text: 'any message',
      },
    ])
  })

  it('returns timezone hints when valid date and different timezones', () => {
    const date = '2023-05-15T12:00:00Z'
    const result = generateMessages(date)
    expect(result).toEqual([
      {
        type: 'hint',
        text: 'Local: Mon, May 15, 2023, 5:00 AM',
      },
      {
        type: 'hint',
        text: 'Course: Mon, May 15, 2023, 8:00 AM',
      },
    ])
  })
})

describe('validateDatetime', () => {
  it('returns empty array when date is empty', () => {
    expect(validateDateTime('', '')).toEqual([])
  })

  it('returns empty array for valid date', () => {
    const result = validateDateTime('May 15, 2023', START_AT_DATE)
    expect(result).toEqual([])
  })

  it('returns error for invalid date', () => {
    const result = validateDateTime('Invalid', 'field')
    expect(result).toEqual([
      {
        containerName: 'field',
        instUIControlled: true,
        message: 'Please enter a valid format for a date',
      },
    ])
  })
})

describe('validateStartDateAfterEnd', () => {
  it('returns empty array when dates are valid and in order', () => {
    const result = validateStartDateAfterEnd('May 15, 2023', '10:00 AM', 'May 16, 2023', '11:00 AM')
    expect(result).toEqual([])
  })

  it('returns empty array when dates are invalid', () => {
    const result = validateStartDateAfterEnd('Invalid', '10:00 AM', 'May 15, 2023', '11:00 AM')
    expect(result).toEqual([])
  })

  it('returns error when end date is before start date', () => {
    const result = validateStartDateAfterEnd('2025-06-09T05:31:00.000Z', '2025-06-08T05:31:00.000Z')
    expect(result).toEqual([
      {
        containerName: END_AT_DATE,
        instUIControlled: true,
        message: 'End date cannot be before start date',
      },
    ])
  })
})
