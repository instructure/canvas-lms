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
import SubmissionList from '../SubmissionList'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

describe('SubmissionList', () => {
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

  beforeAll(() => {
    queryClient.setQueryData(['submissionList'], submissionList)
    queryClient.setQueryData(['portfolioPageList', portfolio.id, sectionList[0].id], {
      pages: [{json: pageList}],
    })
  })

  it('renders a list of submissions', async () => {
    const {getByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubmissionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )

    await waitFor(() => {
      expect(getByText('Original Course')).toBeInTheDocument()
      expect(getByText('Original Assignment')).toBeInTheDocument()
    })
  })

  it('renders submission modal when clicking create page', async () => {
    const {getByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubmissionList {...defaultProps} />
      </MockedQueryClientProvider>,
    )

    const modalLink = getByText('Original Course')
    modalLink.click()
    await waitFor(() => {
      expect(getByText('Add Page for Submission')).toBeVisible()
    })
  })
})
