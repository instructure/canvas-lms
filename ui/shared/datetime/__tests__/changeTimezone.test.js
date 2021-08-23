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

const date = new Date('June 7, 2021, 3:00 PM')
const utcOffset = date.getTimezoneOffset() * 60 * 1000

const chinaTZ = 'Asia/Shanghai'
const chinaTZOffset = +8

const americaTZ = 'America/Denver'
const americaTZOffset = -6

const australiaTZ = 'Australia/Adelaide'
const australiaTZOffset = +9.5

describe('changeTimezone::', () => {
  it('converts east', () => {
    const asiaDate = changeTimezone(date, chinaTZ)
    const diff = (asiaDate.getTime() - date.getTime() - utcOffset) / 60 / 60 / 1000
    expect(diff).toBe(chinaTZOffset)
  })

  it('converts west', () => {
    const americaDate = changeTimezone(date, americaTZ)
    const diff = (americaDate.getTime() - date.getTime() - utcOffset) / 60 / 60 / 1000
    expect(diff).toBe(americaTZOffset)
  })

  it('handles fractional time zones', () => {
    const australiaDate = changeTimezone(date, australiaTZ)
    const diff = (australiaDate.getTime() - date.getTime() - utcOffset) / 60 / 60 / 1000
    expect(diff).toBe(australiaTZOffset)
  })
})

describe('utcTimeOffset::', () => {
  it('converts east', () => {
    const asiaOffset = utcTimeOffset(date, chinaTZ)
    expect(asiaOffset).toBe(chinaTZOffset * 60 * 60 * 1000)
  })

  it('converts west', () => {
    const americaOffset = utcTimeOffset(date, americaTZ)
    expect(americaOffset).toBe(americaTZOffset * 60 * 60 * 1000)
  })

  it('detects daylight saving time', () => {
    const winterDate = new Date('January 12, 2021, 10:00 AM')
    const offsetSummer = utcTimeOffset(date, americaTZ)
    const offsetWinter = utcTimeOffset(winterDate, americaTZ)
    expect(offsetSummer - offsetWinter).toBe(1 * 60 * 60 * 1000)
  })
})

describe('utcDateOffset::', () => {
  let testDate

  it('detects the next UTC day', () => {
    testDate = new Date('2021-04-02T02:35:00.000Z') // April 2nd in UTC in the US
    expect(utcDateOffset(testDate, americaTZ)).toBe(1)
  })

  it('detects the previous UTC day', () => {
    testDate = new Date('2021-04-01T18:45:00.000Z') // March 31st in UTC in Australia (4:15am local)
    expect(utcDateOffset(testDate, australiaTZ)).toBe(-1)
  })

  it('detects the same UTC day', () => {
    testDate = new Date('2021-04-02T03:30:00.000Z') // still the middle of April 1 in Australia (1:00pm local)
    expect(utcDateOffset(testDate, australiaTZ)).toBe(0)
  })
})
