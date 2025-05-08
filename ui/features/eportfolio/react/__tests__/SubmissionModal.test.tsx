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
import SubmissionModal from '../SubmissionModal'
import fetchMock from 'fetch-mock'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {generatePageListKey} from '../utils'

jest.mock('@canvas/util/globalUtils', () => ({
  ...jest.requireActual('@canvas/util/globalUtils'),
  assignLocation: jest.fn(),
}))

// Import the mocked module
import * as globalUtils from '@canvas/util/globalUtils'

describe('SubmissionModal', () => {
  const submission = {
    id: '100',
    name: 'Test Submission',
    course_name: 'Test Course',
    assignment_name: 'Test Assignment',
    submitted_at: '2024-10-01T16:12:39Z',
    preview_url: 'path/to/submission',
    attachment_count: 0,
  }
  const sections = [
    {id: 11, name: 'Section 1', position: 1, category_url: 'url/to/section1'},
    {id: 12, name: 'Section 2', position: 2, category_url: 'url/to/section2'},
  ]
  const defaultProps = {
    submission,
    onClose: jest.fn(),
    sections,
    sectionId: 11,
    portfolioId: 1,
    isOpen: true,
  }

  const firstPages = [
    {id: 111, name: 'Page 1', url: 'portfolio/1/page/1'},
    {id: 112, name: 'Page 2', url: 'portfolio/1/page/2'},
  ]
  const secondPages = [
    {id: 113, name: 'Page 3', url: 'portfolio/1/page/3'},
    {id: 114, name: 'Page 4', url: 'portfolio/1/page/4'},
  ]

  const FIRST_SECTION_URI = `/eportfolios/1/categories/${sections[0].id}/pages?page=1&per_page=10`
  const SECOND_SECTION_URI = `/eportfolios/1/categories/${sections[1].id}/pages?page=1&per_page=10`
  const CREATE_URI = `/eportfolios/${defaultProps.portfolioId}/entries`

  beforeEach(() => {
    queryClient.clear()
    fetchMock.restore()
    jest.clearAllMocks()

    queryClient.setQueryData(generatePageListKey(sections[0].id, defaultProps.portfolioId), {
      pages: [{json: firstPages, nextPage: null}],
      pageParams: [null],
    })

    fetchMock.get(FIRST_SECTION_URI, firstPages)
    fetchMock.get(SECOND_SECTION_URI, secondPages)
  })

  afterEach(() => {
    queryClient.clear()
    fetchMock.restore()
    jest.clearAllMocks()
  })

  it('renders a modal', async () => {
    const {getByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubmissionModal {...defaultProps} />
      </MockedQueryClientProvider>,
    )

    await waitFor(() => {
      expect(getByText('Add Page for Submission')).toBeInTheDocument()
      expect(getByText("Pages in 'Section 1'")).toBeInTheDocument()
    })
  })

  it('shows correct pages for each section', async () => {
    const {getByText, unmount} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubmissionModal {...defaultProps} />
      </MockedQueryClientProvider>,
    )

    await waitFor(() => {
      expect(getByText('Page 1')).toBeInTheDocument()
      expect(getByText('Page 2')).toBeInTheDocument()
    })

    unmount()

    queryClient.setQueryData(generatePageListKey(sections[1].id, defaultProps.portfolioId), {
      pages: [{json: secondPages, nextPage: null}],
      pageParams: [null],
    })

    const {getByText: getByTextSecond} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubmissionModal {...defaultProps} sectionId={sections[1].id} />
      </MockedQueryClientProvider>,
    )

    await waitFor(() => {
      expect(getByTextSecond('Page 3')).toBeInTheDocument()
      expect(getByTextSecond('Page 4')).toBeInTheDocument()
    })
  })

  it('creates a new page with the selected submission', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubmissionModal {...defaultProps} />
      </MockedQueryClientProvider>,
    )

    fetchMock.post(CREATE_URI, {
      entry_url: 'path/to/new_entry',
    })

    await waitFor(() => {
      expect(getByTestId('create-page-button')).toBeInTheDocument()
    })

    await user.click(getByTestId('create-page-button'))

    await waitFor(() => {
      expect(fetchMock.called(CREATE_URI)).toBe(true)
      expect(globalUtils.assignLocation).toHaveBeenCalledWith('path/to/new_entry')
    })
  })
})
