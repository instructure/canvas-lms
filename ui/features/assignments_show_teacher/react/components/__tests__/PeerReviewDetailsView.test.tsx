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
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import PeerReviewDetailsView from '../PeerReviewDetailsView'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
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

const mockAssignmentWithoutPeerReview: TeacherAssignmentType = {
  id: '2',
  name: 'Test Assignment Without Peer Review',
  course: {
    lid: '1',
  },
  peerReviews: {
    enabled: false,
  },
} as TeacherAssignmentType

const ENV = {
  CAN_EDIT_ASSIGNMENTS: false,
}

describe('PeerReviewDetailsView', () => {
  let globalEnv: GlobalEnv
  let user: ReturnType<typeof userEvent.setup>

  beforeAll(() => {
    globalEnv = {...window.ENV}
  })

  beforeEach(() => {
    user = userEvent.setup()
    window.ENV = {...globalEnv, ...ENV}
  })

  const renderWithQueryClient = (ui: React.ReactElement) => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return render(<MockedQueryClientProvider client={queryClient}>{ui}</MockedQueryClientProvider>)
  }

  it('renders the allocation rules link', () => {
    renderWithQueryClient(<PeerReviewDetailsView assignment={mockAssignment} canEdit={false} />)

    expect(screen.getByTestId('peer-review-allocation-rules-link')).toBeInTheDocument()
  })

  it('opens the allocation tray when link is clicked', async () => {
    renderWithQueryClient(<PeerReviewDetailsView assignment={mockAssignment} canEdit={false} />)

    const link = screen.getByTestId('peer-review-allocation-rules-link')
    await user.click(link)

    expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()
  })

  it('closes the allocation tray when close is triggered', async () => {
    renderWithQueryClient(<PeerReviewDetailsView assignment={mockAssignment} canEdit={true} />)

    const link = screen.getByTestId('peer-review-allocation-rules-link')
    await user.click(link)

    expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()

    const closeButton = screen.getByTestId('allocation-rules-tray-close-button')
    await user.click(closeButton)

    waitFor(() => {
      expect(screen.queryByTestId('allocation-rules-tray')).not.toBeInTheDocument()
    })
  })
})
