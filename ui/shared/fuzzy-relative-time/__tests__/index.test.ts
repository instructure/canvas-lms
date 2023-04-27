/* Copyright (C) 2020 - present Instructure, Inc.
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

import {fromNow} from '..'

describe('fuzzy-relative-time::', () => {
  let now: number
  beforeEach(() => {
    now = Date.now()
  })
  const thence = (msec: number) => new Date(now + msec).getTime()
  const thenceSec = (sec: number) => thence(1000 * sec)
  const thenceMin = (min: number) => thenceSec(60 * min)
  const thenceHour = (hour: number) => thenceMin(60 * hour)
  const thenceDay = (day: number) => thenceHour(24 * day)
  const thenceYear = (year: number) => thenceDay(365.25 * year)

  // fromNow accepts either a Date object in the past or future,
  // or a numeric value of milliseconds representing same
  it('throws on bad arguments', () => {
    expect(() => fromNow('junk')).toThrow()
    expect(() => fromNow(new Date('junk'))).toThrow()
    expect(() => fromNow(new Date('2020-03-15T12:34:56Z'))).not.toThrow()
    expect(() => fromNow(1584275696000)).not.toThrow()
  })

  it('handles msec values too', () => {
    const inAFewSeconds = now + 5000
    expect(fromNow(inAFewSeconds)).toBe('in a few seconds')
  })

  it('deals with things close to now', () => {
    expect(fromNow(thence(0))).toBe('now')
    expect(fromNow(thence(100))).toBe('now')
    expect(fromNow(thence(-100))).toBe('now')
  })

  it('deals with things within a minute of now', () => {
    expect(fromNow(thence(5000))).toBe('in a few seconds')
    expect(fromNow(thence(-5000))).toBe('a few seconds ago')
    expect(fromNow(thence(50000))).toBe('in less than a minute')
    expect(fromNow(thence(-50000))).toBe('less than a minute ago')
  })

  it('finds the smallest unit to express', () => {
    expect(fromNow(thenceMin(5))).toBe('in 5 minutes')
    expect(fromNow(thenceMin(-50))).toBe('50 minutes ago')
    expect(fromNow(thenceDay(3))).toBe('in 3 days')
    expect(fromNow(thenceDay(-2))).toBe('2 days ago')
  })

  it('rounds to the nearest unit based on the next-smallest unit', () => {
    expect(fromNow(thenceHour(25))).toBe('tomorrow')
    expect(fromNow(thenceHour(23))).toBe('in 23 hours')
    expect(fromNow(thenceHour(40))).toBe('in 2 days')
    expect(fromNow(thenceDay(-13))).toBe('2 weeks ago')
  })

  it('will not go past weeks as a unit', () => {
    expect(fromNow(thenceYear(1))).toBe('in 52 weeks')
    expect(fromNow(thenceYear(-2))).toBe('104 weeks ago')
  })
})
