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
import {MAX_NUM_PEER_REVIEWS} from '../hooks/usePeerReviewSettings'

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
      expect(screen.getByText('Reviews Required*')).toBeInTheDocument()
      expect(screen.getByText('Points per Peer Review')).toBeInTheDocument()
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

    it('resets all field values and clears error messages when checkbox is unchecked', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '-1')
      await user.tab()
      expect(screen.getByText('Number of peer reviews cannot be negative.')).toBeInTheDocument()

      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '-5')
      await user.tab()
      expect(screen.getByText('Points per review cannot be negative.')).toBeInTheDocument()

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const acrossSectionsCheckbox = screen.getByTestId('across-sections-checkbox')
      const withinGroupsCheckbox = screen.getByTestId('within-groups-checkbox')
      const passFailGradingCheckbox = screen.getByTestId('pass-fail-grading-checkbox')
      const anonymityCheckbox = screen.getByTestId('anonymity-checkbox')
      const submissionRequiredCheckbox = screen.getByTestId('submission-required-checkbox')

      await user.click(acrossSectionsCheckbox)
      await user.click(withinGroupsCheckbox)
      await user.click(passFailGradingCheckbox)
      await user.click(anonymityCheckbox)
      await user.click(submissionRequiredCheckbox)

      expect(acrossSectionsCheckbox).toBeChecked()
      expect(withinGroupsCheckbox).toBeChecked()
      expect(passFailGradingCheckbox).toBeChecked()
      expect(anonymityCheckbox).toBeChecked()
      expect(submissionRequiredCheckbox).toBeChecked()

      await user.click(checkbox)

      expect(checkbox).not.toBeChecked()
      expect(screen.queryByText('Review Settings')).not.toBeInTheDocument()

      await user.click(checkbox)

      const reviewsRequiredInputAfter = screen.getByTestId('reviews-required-input')
      const pointsPerReviewInputAfter = screen.getByTestId('points-per-review-input')

      expect(reviewsRequiredInputAfter).toHaveValue(1)
      expect(pointsPerReviewInputAfter).toHaveValue(0)
      expect(
        screen.queryByText('Number of peer reviews cannot be negative.'),
      ).not.toBeInTheDocument()
      expect(screen.queryByText('Points per review cannot be negative.')).not.toBeInTheDocument()

      await user.click(screen.getByText('Advanced Peer Review Configurations'))

      expect(screen.getByTestId('across-sections-checkbox')).not.toBeChecked()
      expect(screen.getByTestId('within-groups-checkbox')).not.toBeChecked()
      expect(screen.getByTestId('pass-fail-grading-checkbox')).not.toBeChecked()
      expect(screen.getByTestId('anonymity-checkbox')).not.toBeChecked()
      expect(screen.getByTestId('submission-required-checkbox')).not.toBeChecked()
    })
  })

  describe('Basic configurations', () => {
    it('updates "total points" when input fields are changed', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
      const totalPointsDisplay = screen.getByTestId('total-peer-review-points')

      expect(reviewsRequiredInput).toHaveValue(1)
      expect(pointsPerReviewInput).toHaveValue(0)
      expect(totalPointsDisplay).toHaveTextContent('0')

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '3')
      expect(reviewsRequiredInput).toHaveValue(3)
      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '1.5')
      expect(pointsPerReviewInput).toHaveValue(1.5)
      expect(totalPointsDisplay).toHaveTextContent('4.5')

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '3')
      expect(reviewsRequiredInput).toHaveValue(3)
      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '2')
      expect(pointsPerReviewInput).toHaveValue(2)
      expect(totalPointsDisplay).toHaveTextContent('6')
    })

    it('displays errors for invalid inputs on "Reviews Required" field', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      const reviewsRequiredInput = screen.getByTestId('reviews-required-input')

      await user.clear(reviewsRequiredInput)
      await user.tab()
      expect(reviewsRequiredInput).toHaveValue(null)
      expect(screen.getByText('Number of peer reviews is required.')).toBeInTheDocument()

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '-2')
      await user.tab()
      expect(reviewsRequiredInput).toHaveValue(-2)
      expect(screen.getByText('Number of peer reviews cannot be negative.')).toBeInTheDocument()

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, `${MAX_NUM_PEER_REVIEWS + 1}`)
      await user.tab()
      expect(reviewsRequiredInput).toHaveValue(MAX_NUM_PEER_REVIEWS + 1)
      expect(
        screen.getByText(`Number of peer reviews cannot exceed ${MAX_NUM_PEER_REVIEWS}.`),
      ).toBeInTheDocument()

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '2.5')
      await user.tab()
      expect(reviewsRequiredInput).toHaveValue(2.5)
      expect(screen.getByText('Number of peer reviews must be a whole number.')).toBeInTheDocument()
    })

    it('displays errors for invalid inputs on "Points per Review" field', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')

      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '-2')
      await user.tab()
      expect(pointsPerReviewInput).toHaveValue(-2)
      expect(screen.getByText('Points per review cannot be negative.')).toBeInTheDocument()
    })

    it('validates on blur for Reviews Required field', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      const reviewsRequiredInput = screen.getByTestId('reviews-required-input')

      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '-3')
      await user.tab() // This will trigger onBlur

      expect(screen.getByText('Number of peer reviews cannot be negative.')).toBeInTheDocument()
    })

    it('validates on blur for Points per Review field', async () => {
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')

      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '-5')
      await user.tab()

      expect(screen.getByText('Points per review cannot be negative.')).toBeInTheDocument()
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
      expect(screen.getByText('Allow peer reviews across sections')).toBeInTheDocument()
      expect(screen.getByTestId('across-sections-checkbox')).toBeInTheDocument()
      expect(screen.getByText('Allow peer reviews within groups')).toBeInTheDocument()
      expect(screen.getByTestId('within-groups-checkbox')).toBeInTheDocument()
    })

    it('opens allocation rules tray when customize link is clicked', async () => {
      const trayLink = screen.getByText('Customize Allocations')
      await user.click(trayLink)

      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()
    })

    it('shows grading option in toggle details', () => {
      expect(screen.getByText('Grading')).toBeInTheDocument()
      expect(screen.getByTestId('pass-fail-grading-checkbox')).toBeInTheDocument()
    })

    it('shows anonymity option in toggle details', () => {
      expect(screen.getByText('Anonymity')).toBeInTheDocument()
      expect(screen.getByTestId('anonymity-checkbox')).toBeInTheDocument()
    })

    it('shows submission requirement option in toggle details', () => {
      expect(screen.getByText('Submission required')).toBeInTheDocument()
      expect(screen.getByTestId('submission-required-checkbox')).toBeInTheDocument()
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
