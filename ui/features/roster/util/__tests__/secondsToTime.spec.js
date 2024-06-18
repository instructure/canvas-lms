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
import secondsToTime from '../secondsToTime'

describe('secondsToTime', () => {
  test('less than one minute', () => {
    expect(secondsToTime(0)).toBe('00:00')
    expect(secondsToTime(1)).toBe('00:01')
    expect(secondsToTime(11)).toBe('00:11')
  })

  test('less than one hour', () => {
    expect(secondsToTime(61)).toBe('01:01')
    expect(secondsToTime(900)).toBe('15:00')
    expect(secondsToTime(3599)).toBe('59:59')
  })

  test('less than 100 hours', () => {
    expect(secondsToTime(32400)).toBe('09:00:00')
    expect(secondsToTime(359999)).toBe('99:59:59')
  })

  test('more than 100 hours', () => {
    expect(secondsToTime(360000)).toBe('100:00:00')
    expect(secondsToTime(478861)).toBe('133:01:01')
    expect(secondsToTime(8000542)).toBe('2222:22:22')
  })
})
