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

import React from 'react'
import useDateTimeFormat from '../index'
import {render} from '@testing-library/react'
import PropTypes from 'prop-types'

const TestComponent = ({formatName, timeZone, locale, date}) => {
  const dateFormatter = useDateTimeFormat(formatName, timeZone, locale)
  return <div className="test-wrapper">{dateFormatter(date)}</div>
}

TestComponent.propTypes = {
  formatName: PropTypes.string.isRequired,
  timeZone: PropTypes.string,
  locale: PropTypes.string,
  date: PropTypes.oneOfType([PropTypes.string, PropTypes.instanceOf(Date)]),
}

const renderHook = ({formatName, timeZone, locale, date}) => {
  const {container} = render(
    <TestComponent formatName={formatName} date={date} timeZone={timeZone} locale={locale} />
  )
  return container.querySelector('.test-wrapper').innerHTML
}

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
    const result = renderHook({
      formatName: 'date.formats.medium_with_weekday',
      date: '2015-08-03T21:22:23Z',
    })
    expect(result).toBe('Mon, Aug 3, 2015')
  })

  it('accepts a Date object as well as an ISO string', () => {
    const result = renderHook({
      formatName: 'date.formats.medium_with_weekday',
      date: new Date('2015-08-03T21:22:23Z'),
    })
    expect(result).toBe('Mon, Aug 3, 2015')
  })

  it('falls back to the default format when given a bad format name', () => {
    const result = renderHook({formatName: 'nonsense', date: new Date('2015-08-03T21:22:23Z')})
    expect(result).toBe('Mon, Aug 3, 2015, 4:22:23 PM CDT')
  })

  it('returns the empty string if given a null date', () => {
    const result = renderHook({formatName: 'date.formats.medium_with_weekday', date: null})
    expect(result).toBe('')
  })

  it('returns the empty string if given an invalid date', () => {
    const result = renderHook({formatName: 'nonsense', date: 'nonsense'})
    expect(result).toBe('')
  })

  it('honors the locale in ENV', () => {
    ENV.LOCALE = 'fr'
    const result = renderHook({
      formatName: 'date.formats.medium_with_weekday',
      date: '2015-08-03T21:22:23Z',
    })
    expect(result).toBe('lun. 3 août 2015')
    ENV.LOCALE = 'en-US'
  })

  it('honors the timezone in ENV', () => {
    ENV.TIMEZONE = 'Etc/UTC'
    const result = renderHook({formatName: 'time.formats.default', date: '2015-08-03T21:22:23Z'})
    expect(result).toBe('Mon, Aug 3, 2015, 9:22:23 PM UTC')
    ENV.TIMEZONE = 'America/Chicago'
  })

  it('honors a locale being passed in', () => {
    const result = renderHook({
      formatName: 'date.formats.medium_with_weekday',
      date: '2017-12-03T21:22:23Z',
      locale: 'de',
    })
    expect(result).toBe('So., 3. Dez. 2017')
  })

  it('honors a timezone being passed in', () => {
    const result = renderHook({
      formatName: 'time.formats.default',
      date: '2015-08-03T21:22:23Z',
      timeZone: 'Etc/UTC',
    })
    expect(result).toBe('Mon, Aug 3, 2015, 9:22:23 PM UTC')
  })

  it('creates a new formatter if the timezone changes', () => {
    let result = renderHook({formatName: 'time.formats.default', date: '2015-08-03T21:22:23Z'})
    expect(result).toBe('Mon, Aug 3, 2015, 4:22:23 PM CDT')
    ENV.TIMEZONE = 'America/New_York'
    result = renderHook({formatName: 'time.formats.default', date: '2015-08-03T21:22:23Z'})
    expect(result).toBe('Mon, Aug 3, 2015, 5:22:23 PM EDT')
    ENV.TIMEZONE = 'America/Chicago'
  })

  it('creates a new formatter if the locale changes', () => {
    let result = renderHook({formatName: 'time.formats.default', date: '2015-12-03T21:22:23Z'})
    expect(result).toBe('Thu, Dec 3, 2015, 3:22:23 PM CST')
    ENV.LOCALE = 'fi'
    result = renderHook({formatName: 'time.formats.default', date: '2015-12-03T21:22:23Z'})
    expect(result).toBe('to 3. jouluk. 2015 klo 15.22.23 UTC-6')
    ENV.TIMEZONE = 'en-US'
  })
})
