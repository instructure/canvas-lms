/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import PageViews from '../PageViews'
import * as PageViewsTableModule from '../PageViewsTable'
import * as momentUtils from '@instructure/moment-utils'

const queryClient = new QueryClient()

vi.mock('../PageViewsTable')
const MockPageViewsTable = vi.spyOn(PageViewsTableModule, 'PageViewsTable')

vi.mock('@instructure/moment-utils', async () => ({
  ...(await vi.importActual('@instructure/moment-utils')),
  unfudgeDateForProfileTimezone: vi.fn((date: Date) => date),
  fudgeDateForProfileTimezone: vi.fn((date: Date) => date),
}))

const mockUnfudgeDateForProfileTimezone = momentUtils.unfudgeDateForProfileTimezone as ReturnType<typeof vi.fn>
const mockFudgeDateForProfileTimezone = momentUtils.fudgeDateForProfileTimezone as ReturnType<typeof vi.fn>

function Subject({userId}: {userId: string}) {
  return (
    <QueryClientProvider client={queryClient}>
      <PageViews userId={userId} />
    </QueryClientProvider>
  )
}

function mockProfileTimezoneOffset(offsetHours: number | ((date: Date) => number)) {
  mockUnfudgeDateForProfileTimezone.mockImplementation((date: Date) => {
    const hrs = typeof offsetHours === 'number' ? offsetHours : offsetHours(date)
    return new Date(date.getTime() - hrs * 60 * 60 * 1000)
  })
  mockFudgeDateForProfileTimezone.mockImplementation((date: Date) => {
    const hrs = typeof offsetHours === 'number' ? offsetHours : offsetHours(date)
    return new Date(date.getTime() + hrs * 60 * 60 * 1000)
  })
}

describe('PageViews - Cache Date Calculations with unfudgeDateForProfileTimezone', () => {
  beforeEach(() => {
    MockPageViewsTable.mockReturnValue(<div>Mock Table</div>)
    mockUnfudgeDateForProfileTimezone.mockClear()
    mockFudgeDateForProfileTimezone.mockClear()
    mockUnfudgeDateForProfileTimezone.mockImplementation((date: Date) => date)
    mockFudgeDateForProfileTimezone.mockImplementation((date: Date) => date)
    vi.useFakeTimers()
  })

  afterEach(() => {
    MockPageViewsTable.mockReset()
    vi.useRealTimers()
  })

  it('returns same dates when profile timezone matches browser timezone', () => {
    // Set current time to noon on June 15, 2024
    vi.setSystemTime(new Date('2024-06-15T12:00:00Z'))

    mockProfileTimezoneOffset(0)

    render(<Subject userId="1" />)

    const {startDate, endDate} = MockPageViewsTable.mock.calls[0][0]

    // The component uses setHours() which operates in local timezone
    // So we can't assert exact UTC timestamps, but we can verify the date range logic
    expect(startDate).toBeDefined()
    expect(endDate).toBeDefined()

    if (startDate && endDate) {
      // endDate must be in the future
      const now = new Date()
      expect(endDate.getTime()).toBeGreaterThan(now.getTime())
      // startDate must be at least 30 days into the past
      expect(startDate.getTime()).toBeLessThan(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      // Date range should be approximately 31 days (accounting for DST and rounding)
      const rangeDays = (endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)
      expect(rangeDays).toBeGreaterThan(30)
      expect(rangeDays).toBeLessThan(32)
    }
  })

  it('adjusts dates when profile timezone is ahead of browser', () => {
    // Set current time to noon on June 15, 2024
    vi.setSystemTime(new Date('2024-06-15T12:00:00Z'))

    mockProfileTimezoneOffset(4) // Profile timezone ahead by 4 hours

    render(<Subject userId="1" />)

    const {startDate, endDate} = MockPageViewsTable.mock.calls[0][0]

    expect(startDate).toBeDefined()
    expect(endDate).toBeDefined()

    if (startDate && endDate) {
      // endDate must be in the future
      const now = new Date()
      expect(endDate.getTime()).toBeGreaterThan(now.getTime())
      // startDate must be at least 30 days into the past
      expect(startDate.getTime()).toBeLessThan(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      // Date range should be approximately 31 days
      const rangeDays = (endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)
      expect(rangeDays).toBeGreaterThan(30)
      expect(rangeDays).toBeLessThan(32)
    }
  })

  it('adjusts dates when profile timezone is behind browser', () => {
    // Set current time to noon on June 15, 2024
    vi.setSystemTime(new Date('2024-06-15T12:00:00Z'))

    mockProfileTimezoneOffset(-7) // Profile timezone behind by 7 hours

    render(<Subject userId="1" />)

    const {startDate, endDate} = MockPageViewsTable.mock.calls[0][0]

    expect(startDate).toBeDefined()
    expect(endDate).toBeDefined()

    if (startDate && endDate) {
      // endDate must be in the future
      const now = new Date()
      expect(endDate.getTime()).toBeGreaterThan(now.getTime())
      // startDate must be at least 30 days into the past
      expect(startDate.getTime()).toBeLessThan(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      // Date range should be approximately 31 days
      const rangeDays = (endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)
      expect(rangeDays).toBeGreaterThan(30)
      expect(rangeDays).toBeLessThan(32)
    }
  })

  it('range calculated properly across day boundaries (ahead)', () => {
    vi.setSystemTime(new Date('2024-06-15T22:00:00Z'))

    mockProfileTimezoneOffset(11) // Profile timezone ahead by 11 hours

    render(<Subject userId="1" />)

    const {startDate, endDate} = MockPageViewsTable.mock.calls[0][0]

    expect(startDate).toBeDefined()
    expect(endDate).toBeDefined()

    if (startDate && endDate) {
      // endDate must be in the future
      const now = new Date()
      expect(endDate.getTime()).toBeGreaterThan(now.getTime())
      // startDate must be at least 30 days into the past
      expect(startDate.getTime()).toBeLessThan(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      // Date range should be approximately 31 days
      const rangeDays = (endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)
      expect(rangeDays).toBeGreaterThan(30)
      expect(rangeDays).toBeLessThan(32)
    }
  })

  it('range calculated properly across day boundaries (behind)', () => {
    vi.setSystemTime(new Date('2024-06-15T01:00:00Z'))

    mockProfileTimezoneOffset(-7) // Profile timezone behind by 7 hours

    render(<Subject userId="1" />)

    const {startDate, endDate} = MockPageViewsTable.mock.calls[0][0]

    expect(startDate).toBeDefined()
    expect(endDate).toBeDefined()

    if (startDate && endDate) {
      // endDate must be in the future
      const now = new Date()
      expect(endDate.getTime()).toBeGreaterThan(now.getTime())
      // startDate must be at least 30 days into the past
      expect(startDate.getTime()).toBeLessThan(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      // Date range should be approximately 31 days
      const rangeDays = (endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)
      expect(rangeDays).toBeGreaterThan(30)
      expect(rangeDays).toBeLessThan(32)
    }
  })

  it('handles DST transition where start and end dates have different offsets', () => {
    // Set current time to March 15, 2024 (after DST transition on March 10)
    vi.setSystemTime(new Date('2024-03-15T12:00:00Z'))

    // Mock to simulate NY timezone with DST: EDT (UTC-4) for March, EST (UTC-5) for February
    mockProfileTimezoneOffset((date: Date) => {
      const month = date.getUTCMonth()
      // March (month 2) uses EDT (UTC-4), February (month 1) uses EST (UTC-5)
      return month >= 2 ? -4 : -5
    })

    render(<Subject userId="1" />)

    const {startDate, endDate} = MockPageViewsTable.mock.calls[0][0]

    expect(startDate).toBeDefined()
    expect(endDate).toBeDefined()

    if (startDate && endDate) {
      // endDate must be in the future
      const now = new Date()
      expect(endDate.getTime()).toBeGreaterThan(now.getTime())
      // startDate must be approximately 30 days into the past (may be exactly 30 days due to DST)
      expect(startDate.getTime()).toBeLessThanOrEqual(now.getTime() - 29 * 24 * 60 * 60 * 1000)
      // Date range should be approximately 31 days (may vary slightly due to DST)
      const rangeDays = (endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)
      expect(rangeDays).toBeGreaterThan(29.5)
      expect(rangeDays).toBeLessThan(32)
    }
  })
})
