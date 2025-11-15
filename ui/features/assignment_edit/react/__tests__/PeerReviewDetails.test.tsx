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
  PEER_REVIEW_ALLOCATION_ENABLED: true,
  PEER_REVIEW_GRADING_ENABLED: true,
}

const createMockAssignment = (overrides = {}) => ({
  peerReviews: jest.fn(() => false),
  peerReviewCount: jest.fn(() => 1),
  moderatedGrading: jest.fn(() => false),
  courseID: jest.fn(() => '123'),
  getId: jest.fn(() => '456'),
  peerReviewSubmissionRequired: jest.fn(() => false),
  groupCategoryId: jest.fn(() => null),
  peerReviewAcrossSections: jest.fn(() => true),
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

    it('loads initial value of submission required as checked when set to true in assignment', async () => {
      assignment.peerReviews = jest.fn(() => true)
      assignment.peerReviewSubmissionRequired = jest.fn(() => true)

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const submissionRequiredCheckbox = screen.getByTestId('submission-required-checkbox')
      expect(submissionRequiredCheckbox).toBeChecked()
    })

    it('defaults submission required to unchecked when not set in assignment', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const submissionRequiredCheckbox = screen.getByTestId('submission-required-checkbox')
      expect(submissionRequiredCheckbox).not.toBeChecked()
    })

    it('loads initial value of across sections as checked when set to true in assignment', async () => {
      assignment.peerReviews = jest.fn(() => true)
      assignment.peerReviewAcrossSections = jest.fn(() => true)

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const acrossSectionsCheckbox = screen.getByTestId('across-sections-checkbox')
      expect(acrossSectionsCheckbox).toBeChecked()
    })

    it('defaults across sections to checked when not set in assignment', async () => {
      assignment.peerReviews = jest.fn(() => true)
      assignment.peerReviewAcrossSections = jest.fn(() => true)

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const acrossSectionsCheckbox = screen.getByTestId('across-sections-checkbox')
      expect(acrossSectionsCheckbox).toBeChecked()
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

      await user.click(pointsPerReviewInput)
      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '-5')
      await user.tab()
      expect(screen.getByText('Points per review cannot be negative.')).toBeInTheDocument()

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      const acrossSectionsCheckbox = screen.getByTestId('across-sections-checkbox')
      const passFailGradingCheckbox = screen.getByTestId('pass-fail-grading-checkbox')
      const anonymityCheckbox = screen.getByTestId('anonymity-checkbox')
      const submissionRequiredCheckbox = screen.getByTestId('submission-required-checkbox')

      await user.click(acrossSectionsCheckbox)
      await user.click(passFailGradingCheckbox)
      await user.click(anonymityCheckbox)
      await user.click(submissionRequiredCheckbox)

      expect(acrossSectionsCheckbox).not.toBeChecked()
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

      expect(screen.getByTestId('across-sections-checkbox')).toBeChecked()
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
      expect(screen.getByText('Allow peer reviews across sections')).toBeInTheDocument()
      expect(screen.getByTestId('across-sections-checkbox')).toBeInTheDocument()
    })

    it('does not show within groups toggle when assignment is not a group assignment', () => {
      expect(screen.queryByText('Allow peer reviews within groups')).not.toBeInTheDocument()
      expect(screen.queryByTestId('within-groups-checkbox')).not.toBeInTheDocument()
    })

    it('toggles across sections checkbox when clicked', async () => {
      const acrossSectionsCheckbox = screen.getByTestId('across-sections-checkbox')

      expect(acrossSectionsCheckbox).toBeChecked()

      await user.click(acrossSectionsCheckbox)
      expect(acrossSectionsCheckbox).not.toBeChecked()

      await user.click(acrossSectionsCheckbox)
      expect(acrossSectionsCheckbox).toBeChecked()
    })
  })

  describe('Group assignment toggle visibility', () => {
    beforeEach(() => {
      const mockCheckbox = document.createElement('input')
      mockCheckbox.type = 'checkbox'
      mockCheckbox.id = 'has_group_category'
      document.body.appendChild(mockCheckbox)
    })

    afterEach(() => {
      const mockCheckbox = document.getElementById('has_group_category')
      if (mockCheckbox) {
        document.body.removeChild(mockCheckbox)
      }
    })

    it('shows within groups toggle when assignment is a group assignment', async () => {
      const mockCheckbox = document.getElementById('has_group_category') as HTMLInputElement
      mockCheckbox.checked = true
      assignment.groupCategoryId = jest.fn(() => '123')

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      expect(screen.getByText('Allow peer reviews within groups')).toBeInTheDocument()
      expect(screen.getByTestId('within-groups-checkbox')).toBeInTheDocument()
    })

    it('hides within groups toggle when assignment has blank group category', async () => {
      const mockCheckbox = document.getElementById('has_group_category') as HTMLInputElement
      mockCheckbox.checked = false
      assignment.groupCategoryId = jest.fn(() => 'blank')

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      expect(screen.queryByText('Allow peer reviews within groups')).not.toBeInTheDocument()
      expect(screen.queryByTestId('within-groups-checkbox')).not.toBeInTheDocument()
    })

    it('shows within groups toggle when group_category_changed event fires with group category', async () => {
      const mockCheckbox = document.getElementById('has_group_category') as HTMLInputElement
      mockCheckbox.checked = false
      assignment.groupCategoryId = jest.fn(() => null)

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      expect(screen.queryByText('Allow peer reviews within groups')).not.toBeInTheDocument()

      mockCheckbox.checked = true
      assignment.groupCategoryId = jest.fn(() => '456')
      fireEvent(document, new Event('group_category_changed'))

      await waitFor(() => {
        expect(screen.getByText('Allow peer reviews within groups')).toBeInTheDocument()
        expect(screen.getByTestId('within-groups-checkbox')).toBeInTheDocument()
      })
    })

    it('hides within groups toggle when group_category_changed event fires without group category', async () => {
      const mockCheckbox = document.getElementById('has_group_category') as HTMLInputElement
      mockCheckbox.checked = true
      assignment.groupCategoryId = jest.fn(() => '789')

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      expect(screen.getByText('Allow peer reviews within groups')).toBeInTheDocument()

      mockCheckbox.checked = false
      assignment.groupCategoryId = jest.fn(() => null)
      fireEvent(document, new Event('group_category_changed'))

      await waitFor(() => {
        expect(screen.queryByText('Allow peer reviews within groups')).not.toBeInTheDocument()
        expect(screen.queryByTestId('within-groups-checkbox')).not.toBeInTheDocument()
      })
    })

    it('hides within groups toggle when group_category_changed event fires with blank', async () => {
      const mockCheckbox = document.getElementById('has_group_category') as HTMLInputElement
      mockCheckbox.checked = true
      assignment.groupCategoryId = jest.fn(() => '999')

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      expect(screen.getByText('Allow peer reviews within groups')).toBeInTheDocument()

      mockCheckbox.checked = false
      assignment.groupCategoryId = jest.fn(() => 'blank')
      fireEvent(document, new Event('group_category_changed'))

      await waitFor(() => {
        expect(screen.queryByText('Allow peer reviews within groups')).not.toBeInTheDocument()
        expect(screen.queryByTestId('within-groups-checkbox')).not.toBeInTheDocument()
      })
    })

    it('falls back to assignment model when checkbox is not present', async () => {
      const mockCheckbox = document.getElementById('has_group_category')
      if (mockCheckbox) {
        document.body.removeChild(mockCheckbox)
      }

      assignment.groupCategoryId = jest.fn(() => '123')
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const checkbox = screen.getByTestId('peer-review-checkbox')
      await user.click(checkbox)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

      expect(screen.getByText('Allow peer reviews within groups')).toBeInTheDocument()
      expect(screen.getByTestId('within-groups-checkbox')).toBeInTheDocument()
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

    it('unchecks checkbox when disabled', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      await user.click(advancedSettingsToggle)

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

  describe('Feature flag toggles', () => {
    // @ts-expect-error
    const originalEnv = global.ENV

    afterEach(() => {
      // @ts-expect-error
      global.ENV = originalEnv
    })

    describe('when only PEER_REVIEW_GRADING_ENABLED is true', () => {
      beforeEach(() => {
        // @ts-expect-error
        global.ENV = {
          ...originalEnv,
          PEER_REVIEW_GRADING_ENABLED: true,
          PEER_REVIEW_ALLOCATION_ENABLED: false,
        }
      })

      it('shows Reviews Required and grading features', async () => {
        renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        expect(screen.getByText('Reviews Required*')).toBeInTheDocument()
        expect(screen.getByTestId('reviews-required-input')).toBeInTheDocument()
        expect(screen.getByText('Points per Peer Review')).toBeInTheDocument()
        expect(screen.getByTestId('points-per-review-input')).toBeInTheDocument()
        expect(screen.getByText('Total Points for Peer Review(s)')).toBeInTheDocument()

        const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
        await user.click(advancedSettingsToggle)

        expect(screen.getByText('Grading')).toBeInTheDocument()
        expect(screen.getByTestId('pass-fail-grading-checkbox')).toBeInTheDocument()
      })

      it('hides allocation-specific features when only grading is enabled', async () => {
        renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
        await user.click(advancedSettingsToggle)

        expect(screen.queryByText('Allocations')).not.toBeInTheDocument()
        expect(screen.queryByText('Anonymity')).not.toBeInTheDocument()
        expect(screen.queryByText('Submission required')).not.toBeInTheDocument()
      })

      describe('validatePeerReviewDetails function', () => {
        it('returns true when all fields are valid', async () => {
          const container = document.createElement('div')
          container.id = 'peer_reviews_allocation_and_grading_details'
          document.body.appendChild(container)

          const client = new QueryClient()
          render(
            <MockedQueryClientProvider client={client}>
              <PeerReviewDetails assignment={assignment} />
            </MockedQueryClientProvider>,
            {container},
          )
          const checkbox = screen.getByTestId('peer-review-checkbox')
          await user.click(checkbox)

          const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
          await user.clear(reviewsRequiredInput)
          await user.type(reviewsRequiredInput, '5')

          const validateFn = (container as any).validatePeerReviewDetails
          expect(validateFn).toBeDefined()

          const isValid = validateFn()
          expect(isValid).toBe(true)

          document.body.removeChild(container)
        })

        it('returns false when reviewsRequired field is invalid', async () => {
          const container = document.createElement('div')
          container.id = 'peer_reviews_allocation_and_grading_details'
          document.body.appendChild(container)

          const client = new QueryClient()
          render(
            <MockedQueryClientProvider client={client}>
              <PeerReviewDetails assignment={assignment} />
            </MockedQueryClientProvider>,
            {container},
          )
          const checkbox = screen.getByTestId('peer-review-checkbox')
          await user.click(checkbox)

          const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
          await user.clear(reviewsRequiredInput)
          await user.type(reviewsRequiredInput, '-1')
          await user.tab()

          const validateFn = (container as any).validatePeerReviewDetails
          const isValid = validateFn()

          expect(isValid).toBe(false)
          expect(screen.getByText('Number of peer reviews cannot be negative.')).toBeInTheDocument()

          document.body.removeChild(container)
        })

        it('returns false when pointsPerReview field is invalid', async () => {
          const container = document.createElement('div')
          container.id = 'peer_reviews_allocation_and_grading_details'
          document.body.appendChild(container)

          const client = new QueryClient()
          render(
            <MockedQueryClientProvider client={client}>
              <PeerReviewDetails assignment={assignment} />
            </MockedQueryClientProvider>,
            {container},
          )
          const checkbox = screen.getByTestId('peer-review-checkbox')
          await user.click(checkbox)

          const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
          await user.clear(reviewsRequiredInput)
          await user.type(reviewsRequiredInput, '5')

          const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
          await user.click(pointsPerReviewInput)
          await user.clear(pointsPerReviewInput)
          await user.type(pointsPerReviewInput, '-5')
          await user.tab()

          const validateFn = (container as any).validatePeerReviewDetails
          const isValid = validateFn()

          expect(isValid).toBe(false)
          expect(screen.getByText('Points per review cannot be negative.')).toBeInTheDocument()

          document.body.removeChild(container)
        })
      })
    })

    describe('when only PEER_REVIEW_ALLOCATION_ENABLED is true', () => {
      beforeEach(() => {
        // @ts-expect-error
        global.ENV = {
          ...originalEnv,
          PEER_REVIEW_GRADING_ENABLED: false,
          PEER_REVIEW_ALLOCATION_ENABLED: true,
        }
      })

      it('shows Reviews Required and allocation features', async () => {
        renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        expect(screen.getByText('Reviews Required*')).toBeInTheDocument()
        expect(screen.getByTestId('reviews-required-input')).toBeInTheDocument()

        const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
        await user.click(advancedSettingsToggle)

        expect(screen.getByText('Allocations')).toBeInTheDocument()
        expect(screen.getByTestId('across-sections-checkbox')).toBeInTheDocument()
        expect(screen.getByText('Anonymity')).toBeInTheDocument()
        expect(screen.getByTestId('anonymity-checkbox')).toBeInTheDocument()
        expect(screen.getByText('Submission required')).toBeInTheDocument()
        expect(screen.getByTestId('submission-required-checkbox')).toBeInTheDocument()
      })

      it('hides grading-specific features when only allocation is enabled', async () => {
        renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        expect(screen.queryByText('Points per Peer Review')).not.toBeInTheDocument()
        expect(screen.queryByTestId('points-per-review-input')).not.toBeInTheDocument()
        expect(screen.queryByText('Total Points for Peer Review(s)')).not.toBeInTheDocument()

        const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
        await user.click(advancedSettingsToggle)

        expect(screen.queryByText('Grading')).not.toBeInTheDocument()
        expect(screen.queryByTestId('pass-fail-grading-checkbox')).not.toBeInTheDocument()
      })

      it('validates only reviewsRequired when grading is disabled', async () => {
        const container = document.createElement('div')
        container.id = 'peer_reviews_allocation_and_grading_details'
        document.body.appendChild(container)

        const client = new QueryClient()
        render(
          <MockedQueryClientProvider client={client}>
            <PeerReviewDetails assignment={assignment} />
          </MockedQueryClientProvider>,
          {container},
        )
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
        await user.clear(reviewsRequiredInput)
        await user.type(reviewsRequiredInput, '5')

        const validateFn = (container as any).validatePeerReviewDetails
        expect(validateFn).toBeDefined()

        const isValid = validateFn()
        expect(isValid).toBe(true)

        document.body.removeChild(container)
      })

      it('focuses only on reviewsRequired field when grading is disabled', async () => {
        const container = document.createElement('div')
        container.id = 'peer_reviews_allocation_and_grading_details'
        document.body.appendChild(container)

        const client = new QueryClient()
        render(
          <MockedQueryClientProvider client={client}>
            <PeerReviewDetails assignment={assignment} />
          </MockedQueryClientProvider>,
          {container},
        )
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
        await user.clear(reviewsRequiredInput)
        await user.type(reviewsRequiredInput, '-1')
        await user.tab()

        expect(screen.getByText('Number of peer reviews cannot be negative.')).toBeInTheDocument()

        const focusFn = (container as any).focusOnFirstError
        expect(focusFn).toBeDefined()

        focusFn()

        expect(document.activeElement).toBe(reviewsRequiredInput)

        document.body.removeChild(container)
      })
    })

    describe('when both flags are enabled', () => {
      beforeEach(() => {
        // @ts-expect-error
        global.ENV = {
          ...originalEnv,
          PEER_REVIEW_GRADING_ENABLED: true,
          PEER_REVIEW_ALLOCATION_ENABLED: true,
        }
      })

      it('shows all features when both flags are enabled', async () => {
        renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)
        const checkbox = screen.getByTestId('peer-review-checkbox')
        await user.click(checkbox)

        expect(screen.getByText('Reviews Required*')).toBeInTheDocument()
        expect(screen.getByText('Points per Peer Review')).toBeInTheDocument()
        expect(screen.getByText('Total Points for Peer Review(s)')).toBeInTheDocument()

        const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
        await user.click(advancedSettingsToggle)

        expect(screen.getByText('Allocations')).toBeInTheDocument()
        expect(screen.getByText('Grading')).toBeInTheDocument()
        expect(screen.getByText('Anonymity')).toBeInTheDocument()
        expect(screen.getByText('Submission required')).toBeInTheDocument()
      })

      describe('validatePeerReviewDetails function', () => {
        it('validates both reviewsRequired and pointsPerReview when both flags enabled', async () => {
          const container = document.createElement('div')
          container.id = 'peer_reviews_allocation_and_grading_details'
          document.body.appendChild(container)

          const client = new QueryClient()
          render(
            <MockedQueryClientProvider client={client}>
              <PeerReviewDetails assignment={assignment} />
            </MockedQueryClientProvider>,
            {container},
          )
          const checkbox = screen.getByTestId('peer-review-checkbox')
          await user.click(checkbox)

          const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
          await user.clear(reviewsRequiredInput)
          await user.type(reviewsRequiredInput, '5')

          const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
          await user.clear(pointsPerReviewInput)
          await user.type(pointsPerReviewInput, '10')

          const validateFn = (container as any).validatePeerReviewDetails
          expect(validateFn).toBeDefined()

          const isValid = validateFn()
          expect(isValid).toBe(true)

          document.body.removeChild(container)
        })

        it('returns false when pointsPerReview is invalid with both flags enabled', async () => {
          const container = document.createElement('div')
          container.id = 'peer_reviews_allocation_and_grading_details'
          document.body.appendChild(container)

          const client = new QueryClient()
          render(
            <MockedQueryClientProvider client={client}>
              <PeerReviewDetails assignment={assignment} />
            </MockedQueryClientProvider>,
            {container},
          )
          const checkbox = screen.getByTestId('peer-review-checkbox')
          await user.click(checkbox)

          const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
          await user.clear(reviewsRequiredInput)
          await user.type(reviewsRequiredInput, '5')

          const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
          await user.click(pointsPerReviewInput)
          await user.clear(pointsPerReviewInput)
          await user.type(pointsPerReviewInput, '-5')
          await user.tab()

          const validateFn = (container as any).validatePeerReviewDetails
          const isValid = validateFn()

          expect(isValid).toBe(false)
          expect(screen.getByText('Points per review cannot be negative.')).toBeInTheDocument()

          document.body.removeChild(container)
        })
      })
    })
  })

  describe('Function attachment and cleanup', () => {
    it('attaches validatePeerReviewDetails function to DOM element on mount', async () => {
      const container = document.createElement('div')
      container.id = 'peer_reviews_allocation_and_grading_details'
      document.body.appendChild(container)

      const client = new QueryClient()
      render(
        <MockedQueryClientProvider client={client}>
          <PeerReviewDetails assignment={assignment} />
        </MockedQueryClientProvider>,
        {container},
      )

      expect((container as any).validatePeerReviewDetails).toBeDefined()
      expect(typeof (container as any).validatePeerReviewDetails).toBe('function')

      document.body.removeChild(container)
    })

    it('cleans up validatePeerReviewDetails function on unmount', async () => {
      const container = document.createElement('div')
      container.id = 'peer_reviews_allocation_and_grading_details'
      document.body.appendChild(container)

      const client = new QueryClient()
      const {unmount} = render(
        <MockedQueryClientProvider client={client}>
          <PeerReviewDetails assignment={assignment} />
        </MockedQueryClientProvider>,
        {container},
      )

      expect((container as any).validatePeerReviewDetails).toBeDefined()

      unmount()

      expect((container as any).validatePeerReviewDetails).toBeUndefined()

      document.body.removeChild(container)
    })

    it('attaches focusOnFirstError function to DOM element on mount', async () => {
      const container = document.createElement('div')
      container.id = 'peer_reviews_allocation_and_grading_details'
      document.body.appendChild(container)

      const client = new QueryClient()
      render(
        <MockedQueryClientProvider client={client}>
          <PeerReviewDetails assignment={assignment} />
        </MockedQueryClientProvider>,
        {container},
      )

      expect((container as any).focusOnFirstError).toBeDefined()
      expect(typeof (container as any).focusOnFirstError).toBe('function')

      document.body.removeChild(container)
    })

    it('cleans up focusOnFirstError function on unmount', async () => {
      const container = document.createElement('div')
      container.id = 'peer_reviews_allocation_and_grading_details'
      document.body.appendChild(container)

      const client = new QueryClient()
      const {unmount} = render(
        <MockedQueryClientProvider client={client}>
          <PeerReviewDetails assignment={assignment} />
        </MockedQueryClientProvider>,
        {container},
      )

      expect((container as any).focusOnFirstError).toBeDefined()

      unmount()

      expect((container as any).focusOnFirstError).toBeUndefined()

      document.body.removeChild(container)
    })
  })

  describe('Data loading from existing assignment', () => {
    it('loads existing peer review count', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 5),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 25,
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
      expect(reviewsRequiredInput).toHaveValue(5)
    })

    it('calculates points per review from total points', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 4),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 20,
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
      expect(pointsPerReviewInput).toHaveValue(5) // 20 / 4 = 5
    })

    it('loads pass_fail grading type', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 10,
          grading_type: 'pass_fail',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const passFailCheckbox = screen.getByTestId('pass-fail-grading-checkbox')
      expect(passFailCheckbox).toBeChecked()
    })

    it('loads anonymous peer reviews setting', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        anonymousPeerReviews: jest.fn(() => true),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const anonymityCheckbox = screen.getByTestId('anonymity-checkbox')
      expect(anonymityCheckbox).toBeChecked()
    })

    it('loads intra group peer reviews setting', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        intraGroupPeerReviews: jest.fn(() => true),
        groupCategoryId: jest.fn(() => '123'), // Make it a group assignment
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const withinGroupsCheckbox = screen.getByTestId('within-groups-checkbox')
      expect(withinGroupsCheckbox).toBeChecked()
    })
  })

  describe('Hidden inputs for Advanced Configuration', () => {
    it('creates hidden inputs for toggle values when peer reviews are enabled', () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      expect(
        document.getElementById('peer_reviews_within_groups_checkbox_hidden'),
      ).toBeInTheDocument()
      expect(
        document.getElementById('peer_reviews_pass_fail_grading_checkbox_hidden'),
      ).toBeInTheDocument()
      expect(document.getElementById('peer_reviews_anonymity_checkbox_hidden')).toBeInTheDocument()
      expect(
        document.getElementById('peer_reviews_submission_required_checkbox_hidden'),
      ).toBeInTheDocument()
    })

    it('resets peer-review values via hidden inputs when peer reviews are disabled', () => {
      assignment.peerReviews = jest.fn(() => false)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      expect(
        document.getElementById('peer_reviews_within_groups_checkbox_hidden'),
      ).toBeInTheDocument()
      expect(
        document.getElementById('peer_reviews_pass_fail_grading_checkbox_hidden'),
      ).toBeInTheDocument()
      expect(document.getElementById('peer_reviews_anonymity_checkbox_hidden')).toBeInTheDocument()
      expect(
        document.getElementById('peer_reviews_submission_required_checkbox_hidden'),
      ).toBeInTheDocument()
      expect(document.getElementById('assignment_peer_reviews_count_hidden')).toBeInTheDocument()
      expect(
        document.getElementById('assignment_peer_reviews_max_input_hidden'),
      ).toBeInTheDocument()

      expect(
        (document.getElementById('peer_reviews_within_groups_checkbox_hidden') as HTMLInputElement)
          .value,
      ).toBe('false')
      expect(
        (
          document.getElementById(
            'peer_reviews_pass_fail_grading_checkbox_hidden',
          ) as HTMLInputElement
        ).value,
      ).toBe('false')
      expect(
        (document.getElementById('peer_reviews_anonymity_checkbox_hidden') as HTMLInputElement)
          .value,
      ).toBe('false')
      expect(
        (
          document.getElementById(
            'peer_reviews_submission_required_checkbox_hidden',
          ) as HTMLInputElement
        ).value,
      ).toBe('false')
      expect(
        (document.getElementById('assignment_peer_reviews_count_hidden') as HTMLInputElement).value,
      ).toBe('0')
      expect(
        (document.getElementById('assignment_peer_reviews_max_input_hidden') as HTMLInputElement)
          .value,
      ).toBe('0')
    })

    it('within groups hidden input has correct value when enabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        groupCategoryId: jest.fn(() => '123'),
        intraGroupPeerReviews: jest.fn(() => true),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const withinGroupsHidden = document.getElementById(
        'peer_reviews_within_groups_checkbox_hidden',
      ) as HTMLInputElement
      expect(withinGroupsHidden.value).toBe('true')
    })

    it('within groups hidden input has correct value when disabled', () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const withinGroupsHidden = document.getElementById(
        'peer_reviews_within_groups_checkbox_hidden',
      ) as HTMLInputElement
      expect(withinGroupsHidden.value).toBe('false')
    })

    it('anonymity hidden input has correct value when enabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        anonymousPeerReviews: jest.fn(() => true),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const anonymityHidden = document.getElementById(
        'peer_reviews_anonymity_checkbox_hidden',
      ) as HTMLInputElement
      expect(anonymityHidden.value).toBe('true')
    })

    it('anonymity hidden input has correct value when disabled', () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const anonymityHidden = document.getElementById(
        'peer_reviews_anonymity_checkbox_hidden',
      ) as HTMLInputElement
      expect(anonymityHidden.value).toBe('false')
    })

    it('submission required hidden input has correct value when enabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        peerReviewSubmissionRequired: jest.fn(() => true),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const submissionRequiredHidden = document.getElementById(
        'peer_reviews_submission_required_checkbox_hidden',
      ) as HTMLInputElement
      expect(submissionRequiredHidden.value).toBe('true')
    })

    it('submission required hidden input has correct value when disabled', () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const submissionRequiredHidden = document.getElementById(
        'peer_reviews_submission_required_checkbox_hidden',
      ) as HTMLInputElement
      expect(submissionRequiredHidden.value).toBe('false')
    })

    it('pass fail grading hidden input has correct value when enabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 10,
          grading_type: 'pass_fail',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const passFailHidden = document.getElementById(
        'peer_reviews_pass_fail_grading_checkbox_hidden',
      ) as HTMLInputElement
      expect(passFailHidden.value).toBe('true')
    })

    it('pass fail grading hidden input has correct value when disabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 10,
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const passFailHidden = document.getElementById(
        'peer_reviews_pass_fail_grading_checkbox_hidden',
      ) as HTMLInputElement
      expect(passFailHidden.value).toBe('false')
    })

    it('within groups hidden input updates when toggle is changed', async () => {
      assignment.peerReviews = jest.fn(() => true)
      assignment.groupCategoryId = jest.fn(() => '123') // Make it a group assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const withinGroupsCheckbox = screen.getByTestId('within-groups-checkbox')
      await user.click(withinGroupsCheckbox)

      await waitFor(() => {
        const withinGroupsHidden = document.getElementById(
          'peer_reviews_within_groups_checkbox_hidden',
        ) as HTMLInputElement
        expect(withinGroupsHidden.value).toBe('true')
      })
    })

    it('anonymity hidden input updates when toggle is changed', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const anonymityCheckbox = screen.getByTestId('anonymity-checkbox')
      await user.click(anonymityCheckbox)

      await waitFor(() => {
        const anonymityHidden = document.getElementById(
          'peer_reviews_anonymity_checkbox_hidden',
        ) as HTMLInputElement
        expect(anonymityHidden.value).toBe('true')
      })
    })

    it('submission required hidden input updates when toggle is changed', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const submissionRequiredCheckbox = screen.getByTestId('submission-required-checkbox')
      await user.click(submissionRequiredCheckbox)

      await waitFor(() => {
        const submissionRequiredHidden = document.getElementById(
          'peer_reviews_submission_required_checkbox_hidden',
        ) as HTMLInputElement
        expect(submissionRequiredHidden.value).toBe('true')
      })
    })

    it('pass fail grading hidden input updates when toggle is changed', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const advancedSettingsToggle = screen.getByText('Advanced Peer Review Configurations')
      advancedSettingsToggle.click()

      const passFailCheckbox = screen.getByTestId('pass-fail-grading-checkbox')
      await user.click(passFailCheckbox)

      await waitFor(() => {
        const passFailHidden = document.getElementById(
          'peer_reviews_pass_fail_grading_checkbox_hidden',
        ) as HTMLInputElement
        expect(passFailHidden.value).toBe('true')
      })
    })

    it('reviews required hidden input has correct value when peer reviews enabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 3),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const reviewsRequiredHidden = document.getElementById(
        'assignment_peer_reviews_count_hidden',
      ) as HTMLInputElement
      expect(reviewsRequiredHidden.value).toBe('3')
    })

    it('points per review hidden input has correct value when peer reviews enabled', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 2),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 10, // 10 / 2 = 5
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const pointsPerReviewHidden = document.getElementById(
        'assignment_peer_reviews_max_input_hidden',
      ) as HTMLInputElement
      expect(pointsPerReviewHidden.value).toBe('5')
    })

    it('reviews required hidden input updates when user changes value', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const reviewsRequiredInput = screen.getByTestId('reviews-required-input')
      await user.clear(reviewsRequiredInput)
      await user.type(reviewsRequiredInput, '5')
      await user.tab()

      const reviewsRequiredHidden = document.getElementById(
        'assignment_peer_reviews_count_hidden',
      ) as HTMLInputElement
      expect(reviewsRequiredHidden.value).toBe('5')
    })

    it('points per review hidden input updates when user changes value', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '7')
      await user.tab()

      const pointsPerReviewHidden = document.getElementById(
        'assignment_peer_reviews_max_input_hidden',
      ) as HTMLInputElement
      expect(pointsPerReviewHidden.value).toBe('7')
    })

    it('reviews required and points per review hidden inputs reset when peer reviews disabled', async () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 3),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 15,
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      // Verify initial values
      let reviewsRequiredHidden = document.getElementById(
        'assignment_peer_reviews_count_hidden',
      ) as HTMLInputElement
      let pointsPerReviewHidden = document.getElementById(
        'assignment_peer_reviews_max_input_hidden',
      ) as HTMLInputElement
      expect(reviewsRequiredHidden.value).toBe('3')
      expect(pointsPerReviewHidden.value).toBe('5') // 15 / 3 = 5

      // Uncheck peer reviews
      const peerReviewCheckbox = screen.getByTestId('peer-review-checkbox')
      await user.click(peerReviewCheckbox)
      await user.tab()

      reviewsRequiredHidden = document.getElementById(
        'assignment_peer_reviews_count_hidden',
      ) as HTMLInputElement
      pointsPerReviewHidden = document.getElementById(
        'assignment_peer_reviews_max_input_hidden',
      ) as HTMLInputElement
      expect(reviewsRequiredHidden.value).toBe('0')
    })
  })

  describe('Points formatting', () => {
    it('formats points per review with 2 decimals when loaded from database', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 3),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 3.7, // 3.7 / 3 = 1.233333...
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
      expect(pointsPerReviewInput).toHaveValue(1.23) // Should be rounded to 1.23
    })

    it('formats points as integer when value rounds to whole number', () => {
      const assignmentWithData = createMockAssignment({
        peerReviews: jest.fn(() => true),
        peerReviewCount: jest.fn(() => 4),
        peerReviewSubAssignment: jest.fn(() => ({
          points_possible: 31.996, // 31.996 / 4 = 7.999, should round to 8
          grading_type: 'points',
        })),
      }) as unknown as Assignment

      renderWithQueryClient(<PeerReviewDetails assignment={assignmentWithData} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
      expect(pointsPerReviewInput).toHaveValue(8) // Should show as "8" not "8.00"
    })

    it('formats points with 2 decimals after user input and blur', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')

      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '1.126')
      await user.tab()

      expect(pointsPerReviewInput).toHaveValue(1.13) // Should round to 1.13
    })

    it('formats integer input without decimals after blur', async () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')

      await user.clear(pointsPerReviewInput)
      await user.type(pointsPerReviewInput, '5')
      await user.tab()

      expect(pointsPerReviewInput).toHaveValue(5)
    })

    it('shows zero as "0" without decimals', () => {
      assignment.peerReviews = jest.fn(() => true)
      renderWithQueryClient(<PeerReviewDetails assignment={assignment} />)

      const pointsPerReviewInput = screen.getByTestId('points-per-review-input')
      expect(pointsPerReviewInput).toHaveValue(0)
    })
  })
})
