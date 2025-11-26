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
import {render, within, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ReportsTable from '../components/ReportsTable'
import {AccountReportInfo, AccountReport} from '@canvas/account_reports/types'
import fetchMock from 'fetch-mock'

const exampleReports: AccountReportInfo[] = [
  {report: 'report_1', title: 'Report 1', description_html: '<p>Description 1</p>'},
  {
    report: 'report_2',
    title: 'Report 2',
    description_html: '<p>Description 2</p>',
    parameters_html: '<form><input name="foo" type="checkbox"></form>',
    last_run: {
      id: '101',
      report: 'report_2',
      status: 'complete',
      created_at: '2025-01-01T00:00:00Z',
      file_url: 'https://example.com/report_2.csv',
      progress: 100,
      run_time: 10,
      message: 'Report completed successfully',
      parameters: {
        extra_text: 'foo: true',
      },
    },
  },
]

describe('ReportsTable', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('renders a list of reports', () => {
    const {getByTestId} = render(<ReportsTable reports={exampleReports} accountId="123" />)

    const report1_row = getByTestId('tr_report_1')
    expect(report1_row).toBeInTheDocument()
    expect(within(report1_row).getByText('Report 1')).toBeInTheDocument()
    expect(within(report1_row).getByText('Never')).toBeInTheDocument()

    const report2_row = getByTestId('tr_report_2')
    expect(report2_row).toBeInTheDocument()
    expect(within(report2_row).getByText('Report 2')).toBeInTheDocument()
    const downloadLink = within(report2_row).getByText('Download report').closest('a')
    expect(downloadLink).toHaveAttribute('href', 'https://example.com/report_2.csv?download_frd=1')
  })

  it('renders the report description modal when a report is clicked', async () => {
    const user = userEvent.setup()
    const {getByText, findByText} = render(
      <ReportsTable reports={exampleReports} accountId="123" />,
    )
    const button = getByText('Details for Report 1').closest('button')
    await user.click(button!)

    const modalDescription = await findByText('Description 1')
    expect(modalDescription).toBeInTheDocument()
  })

  it('updates content via the ReportAction onStateChange callback', async () => {
    const {getByTestId} = render(<ReportsTable reports={exampleReports} accountId="123" />)
    const user = userEvent.setup()

    const updatedReport: AccountReport = {
      id: '102',
      report: 'report_1',
      status: 'complete',
      created_at: '2025-01-02T00:00:00Z',
      file_url: 'https://example.com/updated_report_1.csv',
      progress: 100,
      run_time: 11,
      message: 'Report completed successfully',
    }
    fetchMock.post('/api/v1/accounts/123/reports/report_1', {
      body: updatedReport,
      status: 200,
    })

    const report1_row = getByTestId('tr_report_1')
    expect(report1_row).toBeInTheDocument()
    const button = within(report1_row).getByText('Run Report')?.closest('button')
    await user.click(button!)

    await waitFor(() => {
      const updatedDownloadLink = within(report1_row).getByText('Download report').closest('a')
      expect(updatedDownloadLink).toHaveAttribute(
        'href',
        'https://example.com/updated_report_1.csv?download_frd=1',
      )
    })
    expect(within(report1_row).getByText('Completed')).toBeInTheDocument()
  })
})
