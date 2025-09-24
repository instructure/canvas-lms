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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import PeerReviewDetails from '../PeerReviewDetails'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

// @ts-expect-error
global.ENV = {
  use_high_contrast: false,
}

const createMockAssignment = (overrides = {}) => ({
  peerReviews: jest.fn(() => false),
  courseID: jest.fn(() => '123'),
  getId: jest.fn(() => '456'),
  ...overrides,
})

function renderWithQueryClient(ui: React.ReactElement) {
  const client = new QueryClient()
  return render(<MockedQueryClientProvider client={client}>{ui}</MockedQueryClientProvider>)
}

describe('PeerReviewDetails', () => {
  let assignment: Assignment
  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    assignment = createMockAssignment() as unknown as Assignment
    assignment.peerReviews = jest.fn(() => false)
    assignment.moderatedGrading = jest.fn(() => false)

    window.removeEventListener('message', jest.fn())
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('Initial rendering', () => {
    it('renders the peer review checkbox', () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      expect(screen.getByLabelText('Require Peer Reviews')).toBeInTheDocument()
    })

    it('renders checkbox as checked when assignment has peer reviews enabled', () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      expect(screen.getByTestId('peer-review-checkbox')).toBeChecked()
    })

    it('does not show settings when peer reviews are unchecked', () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      expect(screen.queryByText('Review Settings')).not.toBeInTheDocument()
      expect(screen.queryByText('Advanced Peer Review Configurations')).not.toBeInTheDocument()
    })

    it('renders checkbox as disabled when assignment is moderated', () => {
      assignment.moderatedGrading = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const checkbox = screen.getByTestId('peer-review-checkbox')
      expect(checkbox).toBeDisabled()
    })
  })

  describe('Checkbox interactions', () => {
    it('shows settings when checkbox is checked', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      expect(checkbox).toBeChecked()
      expect(screen.getByText('Review Settings')).toBeInTheDocument()
      expect(screen.getByText('Advanced Peer Review Configurations')).toBeInTheDocument()
    })

    it('hides settings when checkbox is unchecked', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const checkbox = screen.getByTestId('peer-review-checkbox')
      expect(checkbox).toBeChecked()
      expect(screen.getByText('Review Settings')).toBeInTheDocument()

      await user.click(checkbox)

      expect(checkbox).not.toBeChecked()
      expect(screen.queryByText('Review Settings')).not.toBeInTheDocument()
    })

    it('closes allocation rules tray when checkbox is unchecked', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const trayLink = screen.getByText('Customize Allocations')
      await user.click(trayLink)
      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()

      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      expect(screen.queryByTestId('allocation-rules-tray')).not.toBeInTheDocument()
    })
  })

  describe('Advanced configurations', () => {
    beforeEach(async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)
    })

    it('shows allocations section in toggle details', () => {
      expect(screen.getByText('Allocations')).toBeInTheDocument()
      expect(screen.getByText('Customize Allocations')).toBeInTheDocument()
    })

    it('opens allocation rules tray when customize link is clicked', async () => {
      const trayLink = screen.getByText('Customize Allocations')
      await user.click(trayLink)

      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()
    })
  })

  describe('PostMessage event handling', () => {
    it('disables checkbox when receiving disabled message', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const checkbox = screen.getByTestId('peer-review-checkbox')
      expect(checkbox).not.toBeDisabled()

      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'ASGMT.togglePeerReviews',
            enabled: false,
          },
        }),
      )

      await waitFor(() => {
        expect(checkbox).toBeDisabled()
      })
    })

    it('enables checkbox when receiving enabled message', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'ASGMT.togglePeerReviews',
            enabled: false,
          },
        }),
      )

      await waitFor(() => {
        expect(screen.getByTestId('peer-review-checkbox')).toBeDisabled()
      })

      // Then enable it
      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'ASGMT.togglePeerReviews',
            enabled: true,
          },
        }),
      )

      await waitFor(() => {
        expect(screen.getByTestId('peer-review-checkbox')).not.toBeDisabled()
      })
    })

    it('unchecks checkbox and closes tray when disabled', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const trayLink = screen.getByText('Customize Allocations')
      await user.click(trayLink)
      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()

      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'ASGMT.togglePeerReviews',
            enabled: false,
          },
        }),
      )

      await waitFor(() => {
        expect(screen.getByTestId('peer-review-checkbox')).not.toBeChecked()
        expect(screen.queryByTestId('allocation-rules-tray')).not.toBeInTheDocument()
      })
    })

    it('ignores messages with different subjects', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const checkbox = screen.getByTestId('peer-review-checkbox')
      expect(checkbox).not.toBeDisabled()

      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'DIFFERENT.subject',
            enabled: false,
          },
        }),
      )
      await waitFor(() => {
        expect(checkbox).not.toBeDisabled()
      })
    })
  })
})
