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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssignmentTabs from '../AssignmentTabs'
import {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'

const mockAssignment: TeacherAssignmentType = {
  id: '1',
  name: 'Test Assignment',
  course: {
    lid: '1',
  },
  peerReviews: {
    enabled: true,
  },
} as TeacherAssignmentType

describe('AssignmentTabs', () => {
  it('renders tabs', () => {
    render(<AssignmentTabs assignment={mockAssignment} />)

    expect(screen.getByTestId('assignment-tab')).toBeInTheDocument()
    expect(screen.getByTestId('peer-review-tab')).toBeInTheDocument()
  })

  describe('PeerReviewDetailsView', () => {
    it('renders PeerReviewDetailsView when Peer Review tab is selected and user has permissions', async () => {
      const user = userEvent.setup()
      render(<AssignmentTabs assignment={mockAssignment} />)

      const peerReviewTab = screen.getByTestId('peer-review-tab')
      await user.click(peerReviewTab)

      waitFor(() => {
        expect(screen.getByTestId('peer-review-details-view')).toBeInTheDocument()
      })
    })

    it('does not render PeerReviewDetailsView when user lacks permissions', async () => {
      const user = userEvent.setup()
      render(<AssignmentTabs assignment={mockAssignment} />)

      const peerReviewTab = screen.getByTestId('peer-review-tab')
      await user.click(peerReviewTab)

      waitFor(() => {
        expect(screen.queryByTestId('peer-review-details-view')).not.toBeInTheDocument()
      })
    })
  })
})
