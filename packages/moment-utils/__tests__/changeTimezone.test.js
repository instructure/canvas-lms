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

import {changeTimezone, utcTimeOffset, utcDateOffset} from '../changeTimezone'
import timezone_mock from 'timezone-mock'

const HRS = 60 * 60 * 1000
const MINS = 60 * 1000

function format(date, timeZone) {
  const options = {hour: 'numeric', minute: 'numeric', timeZone, timeZoneName: 'short'}
  return date.toLocaleTimeString('en-US', options)
}

const sampleTime = '3:00 PM'
const date = new Date(`June 7, 2021, ${sampleTime}`)
const dateValue = date.getTime()
const utcOffset = -date.getTimezoneOffset() * MINS

const chinaTZ = 'Asia/Shanghai'
const chinaTZOffset = +8
const chinaTZName = 'GMT+8'

const americaTZ = 'America/Denver'
const americaTZOffset = -6
const americaTZName = 'MDT'

const australiaTZ = 'Australia/Adelaide'
const australiaTZOffset = +9.5
const australiaTZName = 'GMT+9:30'

// local UTC offset in whatever test environment this runs in
const testTZOffset = (Date.UTC(2021, 5, 7, 15) - new Date(2021, 5, 7, 15)) / HRS

describe('changeTimezone::', () => {
  const originalIntl = Intl

  afterEach(() => {
    global.Intl = originalIntl
    timezone_mock.unregister()
  })

  const mockUserTimeZone = function (timeZone) {
    const DateTimeFormat = Intl.DateTimeFormat
    // Replace the global Date object with a mocked one for the specified timezone
    // this makes getTimezoneOffset to use the specified timezone to calculate the offset
    timezone_mock.register(timeZone)
    // Replace browser timezone with a mocked one for the specified timezone
    jest
      .spyOn(global.Intl, 'DateTimeFormat')
      .mockImplementation((locale, options) => new DateTimeFormat(locale, {...options, timeZone}))
  }

  it('does nothing if given no conversion timezones', () => {
    const sameDate = changeTimezone(date, {})
    expect(sameDate.getTime()).toBe(date.getTime())
  })

  it('converts east', () => {
    const asiaDate = changeTimezone(date, {desiredTZ: chinaTZ})
    const diff = (dateValue - asiaDate.getTime() + utcOffset) / HRS
    expect(diff).toBeCloseTo(chinaTZOffset)
    expect(format(asiaDate, chinaTZ)).toBe(`${sampleTime} ${chinaTZName}`)
  })

  it('converts west', () => {
    const americaDate = changeTimezone(date, {desiredTZ: americaTZ})
    const diff = (dateValue - americaDate.getTime() + utcOffset) / HRS
    expect(diff).toBeCloseTo(americaTZOffset)
    expect(format(americaDate, americaTZ)).toBe(`${sampleTime} ${americaTZName}`)
  })

  it('converts back from west to east', () => {
    const originDate = changeTimezone(date, {originTZ: americaTZ})
    const diff = (originDate.getTime() - dateValue + utcOffset) / HRS
    expect(diff).toBeCloseTo(americaTZOffset)
    // can't really check the string here because we don't know what timezone
    // the test runner is running in
  })

  it('handles fractional time zones', () => {
    const australiaDate = changeTimezone(date, {desiredTZ: australiaTZ})
    const diff = (dateValue - australiaDate.getTime() + utcOffset) / HRS
    expect(diff).toBeCloseTo(australiaTZOffset)
    expect(format(australiaDate, australiaTZ)).toBe(`${sampleTime} ${australiaTZName}`)
  })

  it('converts between two different zones that are not ours', () => {
    const asiaDate = changeTimezone(date, {desiredTZ: chinaTZ})
    const asiaToAustraliaDate = changeTimezone(asiaDate, {
      originTZ: chinaTZ,
      desiredTZ: australiaTZ,
    })
    const diff = asiaDate.getTime() - asiaToAustraliaDate.getTime()
    expect(diff).toBeCloseTo((australiaTZOffset - chinaTZOffset) * HRS)
    // this is fun! we've moved the time through two time zone shifts and it should come out
    // the same time of day in the final time zone.
    expect(format(asiaToAustraliaDate, australiaTZ)).toBe(`${sampleTime} ${australiaTZName}`)
  })

  it('keeps consistent dates if the user timezone is shifting to DST', () => {
    // supported by timezone_mock
    const DSTTz = 'US/Eastern'
    // simulate user timezone
    mockUserTimeZone(DSTTz)

    const beforeDST = new Date('2022-03-12 00:00')
    const dstStartDate = new Date('2022-03-13 00:00')
    const dstDate = new Date('2022-03-14 00:00')

    // if user tz is the same as desiredTZ the changeTimezone should return the same date
    // even for DST shifting dates
    const parsedBeforeDSTDate = changeTimezone(beforeDST, {desiredTZ: DSTTz})
    const parsedDSTStartDate = changeTimezone(dstStartDate, {desiredTZ: DSTTz})
    const parsedDSTDate = changeTimezone(dstDate, {desiredTZ: DSTTz})

    expect(parsedDSTStartDate.getTime()).toBe(dstStartDate.getTime())
    expect(parsedBeforeDSTDate.getTime()).toBe(beforeDST.getTime())
    expect(parsedDSTDate.getTime()).toBe(dstDate.getTime())
  })

  it('keeps consistent dates if the user timezone is shifting out from DST', () => {
    // supported by timezone_mock
    const DSTTz = 'US/Eastern'
    // simulate user timezone
    mockUserTimeZone(DSTTz)

    const dstDate = new Date('2022-11-05 00:00')
    const dstEndDate = new Date('2022-11-06 00:00')
    const STDate = new Date('2022-11-07 00:00')

    // if user tz is the same as desiredTZ the changeTimezone should return the same date
    // even for DST shifting dates
    const parsedDSTDate = changeTimezone(dstDate, {desiredTZ: DSTTz})
    const parsedDSTEndDate = changeTimezone(dstEndDate, {desiredTZ: DSTTz})
    const parsedSTDate = changeTimezone(STDate, {desiredTZ: DSTTz})

    expect(parsedDSTDate.getTime()).toBe(dstDate.getTime())
    expect(parsedDSTEndDate.getTime()).toBe(dstEndDate.getTime())
    expect(parsedSTDate.getTime()).toBe(STDate.getTime())
  })
})

describe('utcTimeOffset::', () => {
  it('converts from the engine’s own timezone if no TZ specified', () => {
    const localOffset = utcTimeOffset(date)
    expect(localOffset).toBeCloseTo(testTZOffset * HRS)
  })
  it('converts east', () => {
    const asiaOffset = utcTimeOffset(date, chinaTZ)
    expect(asiaOffset).toBeCloseTo(chinaTZOffset * HRS)
  })

  it('converts west', () => {
    const americaOffset = utcTimeOffset(date, americaTZ)
    expect(americaOffset).toBeCloseTo(americaTZOffset * HRS)
  })

  it('detects daylight saving time', () => {
    const winterDate = new Date('January 12, 2021, 10:00 AM')
    const offsetSummer = utcTimeOffset(date, americaTZ)
    const offsetWinter = utcTimeOffset(winterDate, americaTZ)
    expect(offsetSummer - offsetWinter).toBeCloseTo(1 * HRS)
  })
})

describe('utcDateOffset::', () => {
  let testDate

  it('detects the next UTC day', () => {
    testDate = new Date('2021-04-02T02:35:00.000Z') // ... is April 1st in the US
    expect(utcDateOffset(testDate, americaTZ)).toBe(1)
  })

  it('detects the previous UTC day', () => {
    testDate = new Date('2021-04-01T18:45:00.000Z') // ... is 4:15am April 2nd in Australia
    expect(utcDateOffset(testDate, australiaTZ)).toBe(-1)
  })

  it('still works if the next UTC day is also the next month', () => {
    testDate = new Date('2022-04-01T01:00:00.000Z') // ... is March 31st in the US
    expect(utcDateOffset(testDate, americaTZ)).toBe(1)
  })

  it('still works if the previous UTC day is also the previous month', () => {
    testDate = new Date('2022-03-31T22:00:00.000Z') // ... is April 1st in Australia
    expect(utcDateOffset(testDate, australiaTZ)).toBe(-1)
  })

  it('detects the same UTC day', () => {
    testDate = new Date('2021-04-02T03:30:00.000Z') // still the middle of April 1 in Australia (1:00pm local)
    expect(utcDateOffset(testDate, australiaTZ)).toBe(0)
  })
})
