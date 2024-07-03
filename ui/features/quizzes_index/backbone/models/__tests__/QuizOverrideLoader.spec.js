/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import QuizOverrideLoader from '../QuizOverrideLoader'

describe('QuizOverrideLoader dates selection', () => {
  let loader
  let latestDate
  let middleDate
  let earliestDate
  let dates

  beforeEach(() => {
    loader = QuizOverrideLoader
    latestDate = '2015-04-05'
    middleDate = '2014-04-05'
    earliestDate = '2013-04-05'
    dates = [
      {due_at: latestDate, lock_at: null, unlock_at: middleDate},
      {due_at: middleDate, lock_at: null, unlock_at: earliestDate},
      {due_at: earliestDate, lock_at: null, unlock_at: latestDate},
    ]
  })

  test('can select the latest date from a group', () => {
    expect(loader._chooseLatest(dates, 'due_at')).toBe(latestDate)
  })

  test('can select the earliest date from a group', () => {
    expect(loader._chooseEarliest(dates, 'unlock_at')).toBe(earliestDate)
  })

  test('handles null dates and handles empty arrays', () => {
    let dates_ = [{}, {}]
    expect(loader._chooseLatest(dates_, 'due_at')).toBeFalsy()
    dates_ = []
    expect(loader._chooseLatest(dates_, 'due_at')).toBeFalsy()
  })

  test('returns null if any argument is null', () => {
    const datesWithNull = [...dates, {}]
    expect(loader._chooseLatest(datesWithNull, 'due_at')).toBeNull()
    expect(loader._chooseEarliest(datesWithNull, 'due_at')).toBeNull()
  })
})
