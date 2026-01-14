/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import PageViews, {type PageViewsProps} from '../PageViews'
import * as PageViewsTableModule from '../PageViewsTable'
import {
  fudgeDateForProfileTimezone,
  unfudgeDateForProfileTimezone,
} from '@instructure/moment-utils'

const queryClient = new QueryClient()

vi.mock('../PageViewsTable')
const MockPageViewsTable = vi.spyOn(PageViewsTableModule, 'PageViewsTable')

function Subject(props: PageViewsProps): React.JSX.Element {
  return (
    <QueryClientProvider client={queryClient}>
      <PageViews {...props} />
    </QueryClientProvider>
  )
}

function formatForDisplay(date: Date): string {
  const fmt = new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
  return fmt.format(date)
}

describe('PageViews', () => {
  afterEach(() => {
    MockPageViewsTable.mockReset()
  })

  it('renders the table with the correct props', () => {
    const sent = '123'
    render(<Subject userId={sent} />)
    const {userId, startDate, endDate} = MockPageViewsTable.mock.calls[0][0]
    expect(userId).toBe(sent)
    // By default, start date must be today - 30 days, 00:00
    // Using the same logic as the component: fudge, zero time, unfudge
    const topTimestamp = Date.now() + 24 * 60 * 60 * 1000
    const fudgedTop = fudgeDateForProfileTimezone(new Date(topTimestamp)) ?? new Date(topTimestamp)
    fudgedTop.setHours(0, 0, 0, 0)
    const cacheTopDate = unfudgeDateForProfileTimezone(fudgedTop) ?? fudgedTop
    const bottomTimestamp = topTimestamp - 31 * 24 * 60 * 60 * 1000
    const fudgedBottom =
      fudgeDateForProfileTimezone(new Date(bottomTimestamp)) ?? new Date(bottomTimestamp)
    fudgedBottom.setHours(0, 0, 0, 0)
    const cacheBottomDate = unfudgeDateForProfileTimezone(fudgedBottom) ?? fudgedBottom
    expect(startDate).not.toBeUndefined()
    expect(startDate?.valueOf()).toBe(cacheBottomDate.valueOf())
    // By default, end date must be tomorrow (to include today)
    expect(endDate).not.toBeUndefined()
    expect(endDate?.valueOf()).toBe(cacheTopDate.valueOf())
  })

  it.skip('start date within cache properly passed to the table', async () => {
    const {getByTestId} = render(<Subject userId="1" />)
    // Create yesterday at midnight using the same fudge/unfudge logic as the component
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000)
    const fudgedYesterday =
      fudgeDateForProfileTimezone(yesterday) ?? yesterday
    fudgedYesterday.setHours(0, 0, 0, 0)
    const unfudgedYesterday = unfudgeDateForProfileTimezone(fudgedYesterday) ?? fudgedYesterday

    const dateText = unfudgedYesterday.toISOString().slice(0, 10)
    const date = new Date(dateText)
    const expectedDate = formatForDisplay(date)
    const dateField: HTMLInputElement = getByTestId(
      'page-views-date-start-filter',
    ) as HTMLInputElement
    fireEvent.change(dateField, {target: {value: dateText}})
    fireEvent.blur(dateField)
    expect(dateField.value).toBe(expectedDate) // UTC date
    const {startDate} = MockPageViewsTable.mock.calls[1][0] // second call after rerender
    const expectedStartDate = unfudgeDateForProfileTimezone(date) ?? new Date('1970-01-01')
    expect(startDate?.toISOString()).toBe(expectedStartDate?.toISOString())
  })

  it('start date outside cache must display error', async () => {
    const {getByTestId} = render(<Subject userId="1" />)
    const invalidDate = new Date(Date.now() - 40 * 24 * 60 * 60 * 1000)
    invalidDate.setHours(0, 0, 0, 0)

    const dateText = invalidDate.toISOString().slice(0, 10)
    const date = new Date(dateText)
    const expectedDate = formatForDisplay(date)
    const dateField: HTMLInputElement = getByTestId(
      'page-views-date-start-filter',
    ) as HTMLInputElement
    fireEvent.change(dateField, {target: {value: dateText}})
    fireEvent.blur(dateField)
    expect(dateField.value).toBe(expectedDate) // UTC date
    const errorText = await screen.findByText('Start date must be within the last 30 days.')
    expect(errorText).toBeInTheDocument()
  })

  it('renders the correct label for the date inputs', () => {
    const {getByLabelText} = render(<Subject userId="1" />)
    const input = getByLabelText('Filter start date') as HTMLInputElement
    expect(input).toBeInTheDocument()
    const endInput = getByLabelText('Filter end date') as HTMLInputElement
    expect(endInput).toBeInTheDocument()
  })
})
