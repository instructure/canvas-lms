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
import SubmissionList from '../SubmissionList'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {generatePageListKey} from '../utils'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('SubmissionList', () => {
  let queryClient: QueryClient

  const portfolio = {id: 0, name: 'Test Portfolio', public: true, profile_url: 'path/to/profile'}
  const sectionList = [{name: 'First Section', id: 1, position: 1, category_url: '/path/to/first'}]
  const pageList = [{name: 'First Page', id: 1, url: '/path/to/first', section_id: 1}]
  const submissionList = [
    {
      id: 1,
      name: 'First Submission',
      course_name: 'Original Course',
      assignment_name: 'Original Assignment',
      preview_url: 'path/to/preview',
      submitted_at: '2024-01-01T00:00:00Z',
      attachment_count: 0,
    },
  ]

  const defaultProps = {
    sections: sectionList,
    portfolioId: 0,
    sectionId: 1,
  }

  beforeEach(() => {
    fakeENV.setup({
      LOCALE: 'en',
      flashAlertTimeout: 5000,
    })

    // Set up a fresh QueryClient for each test
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    // Pre-populate the query cache with our test data
    queryClient.setQueryData(['submissionList'], submissionList)
    queryClient.setQueryData(generatePageListKey(sectionList[0].id, portfolio.id), {
      pages: [{json: pageList, nextPage: null}],
      pageParams: [null],
    })

    // Mock the API call for submissions
    fetchMock.get('/eportfolios/0/recent_submissions?page=1&per_page=100', {
      body: submissionList,
      status: 200,
    })
  })

  afterEach(() => {
    queryClient.clear()
    fetchMock.restore()
    fakeENV.teardown()
  })

  const renderWithClient = (ui: React.ReactElement) => {
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('renders a list of submissions', async () => {
    const {getByText} = renderWithClient(<SubmissionList {...defaultProps} />)

    await waitFor(() => {
      expect(getByText('Original Course')).toBeInTheDocument()
      expect(getByText('Original Assignment')).toBeInTheDocument()
    })
  })

  it('renders submission modal when clicking create page', async () => {
    const {getByText, getByTestId, findByTestId} = renderWithClient(
      <SubmissionList {...defaultProps} />,
    )

    // Wait for the submissions to load
    await waitFor(() => {
      expect(getByText('Original Course')).toBeInTheDocument()
    })

    // Click on the course name to open the modal
    const user = userEvent.setup()
    await user.click(getByTestId('submission-modal-1'))

    // Wait for the modal to appear and check its content
    const modal = await findByTestId('create-page-modal')
    expect(modal).toBeInTheDocument()

    // Check for the Create Page button which confirms the modal is open
    const createButton = await findByTestId('create-page-button')
    expect(createButton).toBeInTheDocument()
    expect(createButton).toHaveTextContent('Create Page')
  })
})
