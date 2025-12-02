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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ReportAction from '../components/ReportAction'
import {AccountReportInfo, AccountReport} from '@canvas/account_reports/types'
import fetchMock from 'fetch-mock'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(() => jest.fn()),
}))

function renderWithQueryClient(ui: React.ReactElement) {
  const client = new QueryClient()
  return render(<MockedQueryClientProvider client={client}>{ui}</MockedQueryClientProvider>)
}

const reportWithoutParameters: AccountReportInfo = {
  report: 'report_1',
  title: 'Report 1',
  description_html: '<p>Description 1</p>',
}

const reportWithParameters: AccountReportInfo = {
  report: 'report_1',
  title: 'Report 1',
  description_html: '<p>Description 1</p>',
  parameters_html: '<form><label>foo<input name="foo" type="checkbox"></label></form>',
}

const runningReport: AccountReport = {
  id: '101',
  report: 'report_1',
  status: 'running',
  created_at: '2025-01-02T00:00:00Z',
  progress: 69,
  run_time: 1.1,
  parameters: {
    extra_text: 'foo: true',
  },
}

const completeReport: AccountReport = {
  id: '101',
  report: 'report_1',
  status: 'complete',
  created_at: '2025-01-01T00:00:00Z',
  file_url: 'https://example.com/report_1.csv',
  progress: 100,
  run_time: 33.3,
  parameters: {
    extra_text: 'foo: true',
  },
}

const canceledReport: AccountReport = {
  id: '101',
  report: 'report_1',
  status: 'aborted',
  created_at: '2025-01-01T00:00:00Z',
  progress: 100,
  run_time: 10,
  parameters: {
    extra_text: 'foo: true',
  },
}
describe('ReportAction', () => {
  afterEach(() => {
    fetchMock.restore()
    jest.clearAllMocks()
  })

  describe('report not running', () => {
    beforeEach(() => {
      fetchMock.post('/api/v1/accounts/123/reports/report_1', {
        body: completeReport,
        status: 200,
      })
    })

    it('configures and runs a report with parameters', async () => {
      const spy = jest.fn()
      const user = userEvent.setup()

      const {getByText, getByLabelText} = renderWithQueryClient(
        <ReportAction accountId="123" report={reportWithParameters} onStateChange={spy} />,
      )
      const button = getByText('Configure Run...').closest('button')
      expect(button).toBeInTheDocument()
      await user.click(button!)

      const checkbox = getByLabelText('foo').closest('input')
      await user.click(checkbox!)

      const run_button = getByText('Run Report').closest('button')
      await user.click(run_button!)

      await waitFor(() => {
        expect(spy).toHaveBeenCalledWith(completeReport)
      })
    })

    it('runs a report without parameters', async () => {
      const spy = jest.fn()
      const user = userEvent.setup()

      const {getByText} = renderWithQueryClient(
        <ReportAction accountId="123" report={reportWithoutParameters} onStateChange={spy} />,
      )

      const button = getByText('Run Report').closest('button')
      expect(button).toBeInTheDocument()
      await user.click(button!)

      await waitFor(() => {
        expect(spy).toHaveBeenCalledWith(completeReport)
      })
    })
  })

  it('shows progress for a running report', async () => {
    fetchMock.get('/api/v1/accounts/123/reports/report_1/101', {
      body: runningReport,
      status: 200,
    })

    const {container} = renderWithQueryClient(
      <ReportAction
        accountId="123"
        report={reportWithParameters}
        reportRun={runningReport}
        onStateChange={jest.fn()}
      />,
    )
    const progressBar = container.querySelector('progress')
    expect(progressBar).toBeInTheDocument()
    expect(progressBar).toHaveAttribute('value', '69')
  })

  it('cancels a running report', async () => {
    const user = userEvent.setup()
    const spy = jest.fn()
    fetchMock.get('/api/v1/accounts/123/reports/report_1/101', {
      body: runningReport,
      status: 200,
    })
    fetchMock.put('/api/v1/accounts/123/reports/report_1/101/abort', {
      body: canceledReport,
      status: 200,
    })

    const {getByTestId} = renderWithQueryClient(
      <ReportAction
        accountId="123"
        report={reportWithParameters}
        reportRun={runningReport}
        onStateChange={spy}
      />,
    )

    const cancelButton = getByTestId('cancel-report-button')
    await user.click(cancelButton!)
    await waitFor(() => {
      expect(spy).toHaveBeenCalledWith(canceledReport)
    })
  })

  it('shows an error if canceling fails', async () => {
    const user = userEvent.setup()
    fetchMock.get('/api/v1/accounts/123/reports/report_1/101', {
      body: runningReport,
      status: 200,
    })
    fetchMock.put('/api/v1/accounts/123/reports/report_1/101/abort', {
      body: {message: 'Internal server error'},
      status: 500,
    })

    const {getByTestId} = renderWithQueryClient(
      <ReportAction
        accountId="123"
        report={reportWithParameters}
        reportRun={runningReport}
        onStateChange={jest.fn()}
      />,
    )

    const cancelButton = getByTestId('cancel-report-button')
    await user.click(cancelButton!)

    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith('Error canceling report')
    })
  })

  it('does not show an error if canceling 404s because the report finished already', async () => {
    const user = userEvent.setup()
    fetchMock.get('/api/v1/accounts/123/reports/report_1/101', {
      body: runningReport,
      status: 200,
    })
    fetchMock.put('/api/v1/accounts/123/reports/report_1/101/abort', {
      body: {message: 'Not Found'},
      status: 404,
    })

    const {getByTestId} = renderWithQueryClient(
      <ReportAction
        accountId="123"
        report={reportWithParameters}
        reportRun={runningReport}
        onStateChange={jest.fn()}
      />,
    )

    const cancelButton = getByTestId('cancel-report-button')
    await user.click(cancelButton!)

    // Wait for the fetch to complete, then verify no error was shown
    await waitFor(() => {
      expect(fetchMock.done('/api/v1/accounts/123/reports/report_1/101/abort')).toBe(true)
    })
    expect(showFlashError).not.toHaveBeenCalled()
  })
})
