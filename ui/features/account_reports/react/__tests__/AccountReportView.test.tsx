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
import AccountReportView from '../components/AccountReportView'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('AccountReportView', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    vi.clearAllMocks()
    server.resetHandlers()
  })

  it('fetches reports and renders ReportsTable with correct props', async () => {
    const mockReports = [
      {report: 'report_1', title: 'Report 1', description_html: '<p>Report 1 description</p>'},
    ]

    server.use(
      http.get('/api/v1/accounts/123/reports', () => {
        return HttpResponse.json(mockReports)
      }),
    )

    const {getByText} = render(<AccountReportView accountId="123" />)

    await waitFor(() => {
      expect(getByText('Report 1')).toBeInTheDocument()
    })
  })
})
