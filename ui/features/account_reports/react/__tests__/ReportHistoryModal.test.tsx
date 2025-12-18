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
import {render, within} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import ReportHistoryModal from '../components/ReportHistoryModal'
import {QueryClient} from '@tanstack/react-query'
import {AccountReport} from '@canvas/account_reports/types'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'

function renderWithQueryClient(ui: React.ReactElement) {
  const client = new QueryClient()
  return render(<MockedQueryClientProvider client={client}>{ui}</MockedQueryClientProvider>)
}

const mockHistory = [
  {
    id: '1',
    report: 'report_1',
    status: 'complete',
    created_at: '2025-01-01T00:00:00Z',
    file_url: 'https://example.com/report_1.csv',
    progress: 100,
    message: 'Report completed successfully',
    started_at: '2025-01-01T00:00:01Z',
    ended_at: '2025-01-01T00:05:00Z',
    user: {
      id: '42',
      display_name: 'Test User',
      html_url: 'https://example.com/users/42',
    },
  },
  {
    id: '2',
    report: 'report_1',
    status: 'error',
    created_at: '2025-01-02T00:00:00Z',
    progress: 0,
    message: 'Report failed to complete',
    started_at: '2025-01-01T00:00:01Z',
    user: {
      id: '43',
      display_name: 'Sad User',
      html_url: 'https://example.com/users/43',
    },
  },
]

describe('ReportHistoryModal', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('fetches and renders report history', async () => {
    fetchMock.get('/api/v1/accounts/123/reports/report_1', {
      body: mockHistory,
      status: 200,
    })

    const {getByTestId, findByTestId} = renderWithQueryClient(
      <ReportHistoryModal accountId="123" report="report_1" closeModal={vi.fn()} />,
    )

    const history1 = await findByTestId('report_history_1')
    const downloadLink = within(history1).getByText('Download report').closest('a')
    expect(downloadLink).toHaveAttribute('href', 'https://example.com/report_1.csv?download_frd=1')
    expect(within(history1).getByText('Completed')).toBeInTheDocument()
    expect(within(history1).getByText('Report completed successfully')).toBeInTheDocument()
    expect(within(history1).getByText('Finished:')).toBeInTheDocument()
    expect(within(history1).getByText('Test User')).toBeInTheDocument()

    const history2 = getByTestId('report_history_2')
    expect(within(history2).getByText('Failed')).toBeInTheDocument()
    expect(within(history2).getByText('Report failed to complete')).toBeInTheDocument()
    expect(within(history2).getByText('Sad User')).toBeInTheDocument()
  })

  it('includes dynamic update if present', async () => {
    fetchMock.get('/api/v1/accounts/123/reports/report_1', {
      body: mockHistory,
      status: 200,
    })

    const updatedReport: AccountReport = {
      id: '2',
      report: 'report_1',
      status: 'complete',
      created_at: '2025-01-02T00:00:00Z',
      progress: 100,
      message: "Second time's a charm",
      started_at: '2025-01-01T00:00:01Z',
      ended_at: '2025-01-01T00:05:00Z',
      run_time: 3000,
      user: {
        id: '43',
        display_name: 'Sad User',
        html_url: 'https://example.com/users/43',
      },
    }

    const {findByTestId} = renderWithQueryClient(
      <ReportHistoryModal
        accountId="123"
        report="report_1"
        closeModal={vi.fn()}
        updatedReport={updatedReport}
      />,
    )

    const history2 = await findByTestId('report_history_2')
    expect(within(history2).getByText('Completed')).toBeInTheDocument()
    expect(within(history2).getByText("Second time's a charm")).toBeInTheDocument()
    expect(within(history2).getByText('Sad User')).toBeInTheDocument()
  })

  it('renders a loading spinner while fetching', async () => {
    fetchMock.get('/api/v1/accounts/123/reports/report_1', new Promise(() => {})) // Simulate a pending request

    const {findByLabelText} = renderWithQueryClient(
      <ReportHistoryModal accountId="123" report="report_1" closeModal={vi.fn()} />,
    )

    expect(await findByLabelText('Loading report history...')).toBeInTheDocument()
  })
})
