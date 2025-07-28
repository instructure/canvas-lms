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
import {render, fireEvent} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import PageViews, {type PageViewsProps} from '../PageViews'
import * as PageViewsTableModule from '../PageViewsTable'
import {unfudgeDateForProfileTimezone} from '@instructure/moment-utils'

const queryClient = new QueryClient()

jest.mock('../PageViewsTable')
const MockPageViewsTable = jest.spyOn(PageViewsTableModule, 'PageViewsTable')

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
    expect(startDate).toBeUndefined()
    expect(endDate).toBeUndefined()
  })

  it('passes the date range to the table when specified', async () => {
    const {getByTestId} = render(<Subject userId="1" />)
    const dateText = '2024-12-01'
    const date = new Date(dateText)
    const expectedDate = formatForDisplay(date)
    const dateField: HTMLInputElement = getByTestId('page-views-date-filter') as HTMLInputElement
    fireEvent.change(dateField, {target: {value: dateText}})
    fireEvent.blur(dateField)
    expect(dateField.value).toBe(expectedDate) // UTC date
    const {startDate, endDate} = MockPageViewsTable.mock.calls[1][0] // second call after rerender
    const expectedStartDate = unfudgeDateForProfileTimezone(date) ?? new Date('1970-01-01')
    const expectedEndDate = new Date(expectedStartDate.getTime() + 24 * 60 * 60 * 1000)
    expect(startDate?.toISOString()).toBe(expectedStartDate?.toISOString())
    expect(endDate?.toISOString()).toBe(expectedEndDate?.toISOString())
  })

  it('renders the correct label for the date input', () => {
    const {getByLabelText} = render(<Subject userId="1" />)
    const input = getByLabelText('Filter by date') as HTMLInputElement
    expect(input).toBeInTheDocument()
  })
})
