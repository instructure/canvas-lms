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
import {render, screen} from '@testing-library/react'
import {mockAssignment} from '../../test-utils'
import AssignmentHeader from '../AssignmentHeader'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'

const setUp = (assignment = mockAssignment(), breakpoints = {}) => {
  const queryClient = new QueryClient()
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <AssignmentHeader assignment={assignment} breakpoints={breakpoints} />
    </MockedQueryClientProvider>
  )
}

describe('Options Menu', () => {
  it('renders options button', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    expect(queryByTestId('assignment-options-button')).toBeInTheDocument()
  })

  it('does not render Download Submissions option when there are no submissions', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('download-submissions-option')).not.toBeInTheDocument()
  })

  it('renders Download Submissions option when there are submissions', () => {
    const assignment = mockAssignment({hasSubmittedSubmissions: true})
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('download-submissions-option')).toBeInTheDocument()
  })

  it('does not render Re-Upload Submissions option when there are no submission downloads', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('reupload-submissions-option')).not.toBeInTheDocument()
  })

  it('renders Re-Upload Submissions option when there are submission downloads', () => {
    const assignment = mockAssignment({
      hasSubmittedSubmissions: true,
      submissionsDownloads: 1,
    })
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('reupload-submissions-option')).toBeInTheDocument()
  })

  it('renders Peer Review option when peer reviews are required', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('peer-review-option')).toBeInTheDocument()
  })

  it('does not render Peer Review Option when peer reviews are not required', () => {
    const assignment = mockAssignment()
    assignment.peerReviews.enabled = false
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('peer-review-option')).not.toBeInTheDocument()
  })

  it('renders Send To option', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('send-to-option')).toBeInTheDocument()
  })

  it('renders Copy To option', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('copy-to-option')).toBeInTheDocument()
  })

  it('renders Share To Commons option', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp(assignment)
    queryByTestId('assignment-options-button')?.click()
    expect(queryByTestId('share-to-commons-option')).toBeInTheDocument()
  })

  describe('Mobile View', () => {
    it('renders a more button instead of the traditional icon button', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp(assignment, {mobileOnly: true})
      expect(queryByTestId('assignment-options-button')).toBeInTheDocument()
      expect(screen.getByText('More')).toBeInTheDocument()
    })

    it('renders the Edit option', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp(assignment, {mobileOnly: true})
      queryByTestId('assignment-options-button')?.click()
      expect(queryByTestId('edit-option')).toBeInTheDocument()
    })

    it('renders the Assign To option', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp(assignment, {mobileOnly: true})
      queryByTestId('assignment-options-button')?.click()
      expect(queryByTestId('assign-to-option')).toBeInTheDocument()
    })

    it('renders the SpeedGrader option', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp(assignment, {mobileOnly: true})
      queryByTestId('assignment-options-button')?.click()
      expect(queryByTestId('speedgrader-option')).toBeInTheDocument()
    })
  })
})
