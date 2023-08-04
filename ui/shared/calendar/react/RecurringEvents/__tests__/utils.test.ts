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

import moment from 'moment'
import {
  cardinalDayInMonth,
  getWeekdayName,
  isLastWeekdayInMonth,
  weekdaysFromMoment,
} from '../utils'

const defaultTZ = 'America/New_York'
moment.tz.setDefault(defaultTZ)

describe('weekdaysFromMoment', () => {
  it('returns the correct weekdays', () => {
    expect(weekdaysFromMoment(moment('2023-06-05'))).toEqual(['MO'])
    expect(weekdaysFromMoment(moment('2023-06-06'))).toEqual(['TU'])
    expect(weekdaysFromMoment(moment('2023-06-07'))).toEqual(['WE'])
    expect(weekdaysFromMoment(moment('2023-06-08'))).toEqual(['TH'])
    expect(weekdaysFromMoment(moment('2023-06-09'))).toEqual(['FR'])
    expect(weekdaysFromMoment(moment('2023-06-10'))).toEqual(['SA'])
    expect(weekdaysFromMoment(moment('2023-06-11'))).toEqual(['SU'])
  })
})

describe('cardinalDayInMonth', () => {
  it('returns the correct day', () => {
    expect(cardinalDayInMonth(moment('2023-06-02'))).toEqual({
      cardinal: 1,
      last: false,
      dayOfWeek: 5,
    })
    expect(cardinalDayInMonth(moment('2023-06-09'))).toEqual({
      cardinal: 2,
      last: false,
      dayOfWeek: 5,
    })
    expect(cardinalDayInMonth(moment('2023-06-16'))).toEqual({
      cardinal: 3,
      last: false,
      dayOfWeek: 5,
    })
    expect(cardinalDayInMonth(moment('2023-06-23'))).toEqual({
      cardinal: 4,
      last: false,
      dayOfWeek: 5,
    })
    expect(cardinalDayInMonth(moment('2023-06-30'))).toEqual({
      cardinal: 5,
      last: true,
      dayOfWeek: 5,
    })
    expect(cardinalDayInMonth(moment('2023-07-25'))).toEqual({
      cardinal: 4,
      last: true,
      dayOfWeek: 2,
    })
  })
})

describe('getWeekdayName', () => {
  it('returns the correct weekdays', () => {
    expect(getWeekdayName(moment('2023-06-05'), 'en', defaultTZ)).toEqual('Monday')
    expect(getWeekdayName(moment('2023-06-06'), 'en', defaultTZ)).toEqual('Tuesday')
    expect(getWeekdayName(moment('2023-06-07'), 'en', defaultTZ)).toEqual('Wednesday')
    expect(getWeekdayName(moment('2023-06-08'), 'en', defaultTZ)).toEqual('Thursday')
    expect(getWeekdayName(moment('2023-06-09'), 'en', defaultTZ)).toEqual('Friday')
    expect(getWeekdayName(moment('2023-06-10'), 'en', defaultTZ)).toEqual('Saturday')
    expect(getWeekdayName(moment('2023-06-11'), 'en', defaultTZ)).toEqual('Sunday')
  })
})

describe('isLastWeekdayInMonth', () => {
  it('returns the correct weekdays', () => {
    expect(isLastWeekdayInMonth(moment('2023-06-29'))).toEqual(true)
    expect(isLastWeekdayInMonth(moment('2023-06-22'))).toEqual(false)
  })
})
