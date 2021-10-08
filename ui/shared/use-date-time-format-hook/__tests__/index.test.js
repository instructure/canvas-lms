/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks'
import useDateTimeFormat from '../index'

describe('useDateTimeFormat', () => {
  let oldEnv

  beforeAll(() => {
    oldEnv = ENV
    ENV = {LOCALE: 'en-US', TIMEZONE: 'America/Chicago'}
  })

  afterAll(() => {
    ENV = oldEnv
  })

  it('converts using a given format name', () => {
    const {result} = renderHook(() => useDateTimeFormat('date.formats.medium_with_weekday'))
    const fmt = result.current
    const d = '2015-08-03T21:22:23Z'
    expect(fmt(d)).toBe('Mon, Aug 3, 2015')
  })

  it('accepts a Date object as well as an ISO string', () => {
    const {result} = renderHook(() => useDateTimeFormat('date.formats.medium_with_weekday'))
    const fmt = result.current
    const d = new Date('2015-08-03T21:22:23Z')
    expect(fmt(d)).toBe('Mon, Aug 3, 2015')
  })

  it('falls back to the default format when given a bad format name', () => {
    const {result} = renderHook(() => useDateTimeFormat('nonsense'))
    const fmt = result.current
    const d = '2015-08-03T21:22:23Z'
    expect(fmt(d)).toBe('Mon, Aug 3, 2015, 4:22:23 PM CDT')
  })

  it('returns the empty string if given a null date', () => {
    const {result} = renderHook(() => useDateTimeFormat('date.formats.medium_with_weekday'))
    const fmt = result.current
    expect(fmt(null)).toBe('')
  })

  it('returns the empty string if given an invalid date', () => {
    const {result} = renderHook(() => useDateTimeFormat('nonsense'))
    const fmt = result.current
    const d = 'nonsense'
    expect(fmt(d)).toBe('')
  })

  it('honors the locale in ENV', () => {
    ENV.LOCALE = 'fr'
    const {result} = renderHook(() => useDateTimeFormat('date.formats.medium_with_weekday'))
    const fmt = result.current
    const d = '2015-08-03T21:22:23Z'
    expect(fmt(d)).toBe('lun. 3 août 2015')
    ENV.LOCALE = 'en-US'
  })

  it('honors the timezone in ENV', () => {
    ENV.TIMEZONE = 'Etc/UTC'
    const {result} = renderHook(() => useDateTimeFormat('time.formats.default'))
    const fmt = result.current
    const d = '2015-08-03T21:22:23Z'
    expect(fmt(d)).toBe('Mon, Aug 3, 2015, 9:22:23 PM UTC')
    ENV.TIMEZONE = 'America/Chicago'
  })

  it('honors a locale being passed in', () => {
    const {result} = renderHook(() =>
      useDateTimeFormat('date.formats.medium_with_weekday', undefined, 'de')
    )
    const fmt = result.current
    const d = '2017-12-03T21:22:23Z'
    expect(fmt(d)).toBe('So., 3. Dez. 2017')
  })

  it('honors a timezone being passed in', () => {
    const {result} = renderHook(() => useDateTimeFormat('time.formats.default', 'Etc/UTC'))
    const fmt = result.current
    const d = '2015-08-03T21:22:23Z'
    expect(fmt(d)).toBe('Mon, Aug 3, 2015, 9:22:23 PM UTC')
  })

  it('creates a new formatter if the timezone changes', () => {
    const {result, rerender} = renderHook(() => useDateTimeFormat('time.formats.default'))
    const d = '2015-08-03T21:22:23Z'
    expect(result.current(d)).toBe('Mon, Aug 3, 2015, 4:22:23 PM CDT')
    ENV.TIMEZONE = 'America/New_York'
    rerender()
    expect(result.current(d)).toBe('Mon, Aug 3, 2015, 5:22:23 PM EDT')
    ENV.TIMEZONE = 'America/Chicago'
  })

  it('creates a new formatter if the locale changes', () => {
    const {result, rerender} = renderHook(() => useDateTimeFormat('time.formats.default'))
    const d = '2015-12-03T21:22:23Z'
    expect(result.current(d)).toBe('Thu, Dec 3, 2015, 3:22:23 PM CST')
    ENV.LOCALE = 'fi'
    rerender()
    expect(result.current(d)).toBe('to 3. jouluk. 2015 klo 15.22.23 UTC-6')
    ENV.TIMEZONE = 'en-US'
  })
})
