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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {PeerReviewSelector} from '../PeerReviewSelector'
import {AssessmentRequest} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

describe('PeerReviewSelector', () => {
  const mockAssessmentRequests: AssessmentRequest[] = [
    {
      _id: 'ar-1',
      available: true,
      workflowState: 'assigned',
      createdAt: '2025-11-01T00:00:00Z',
      anonymousId: null,
      anonymizedUser: null,
      submission: {
        _id: 'sub-1',
        attempt: 1,
        body: '<p>Test submission 1</p>',
        submissionType: 'online_text_entry',
        submittedAt: '2025-11-01T00:00:00Z',
      },
    },
    {
      _id: 'ar-2',
      available: true,
      workflowState: 'assigned',
      createdAt: '2025-11-02T00:00:00Z',
      anonymousId: null,
      anonymizedUser: null,
      submission: {
        _id: 'sub-2',
        attempt: 1,
        body: '<p>Test submission 2</p>',
        submissionType: 'online_text_entry',
        submittedAt: '2025-11-02T00:00:00Z',
      },
    },
    {
      _id: 'ar-3',
      available: true,
      workflowState: 'assigned',
      createdAt: '2025-11-03T00:00:00Z',
      anonymousId: null,
      anonymizedUser: null,
      submission: {
        _id: 'sub-3',
        attempt: 1,
        body: '<p>Test submission 3</p>',
        submissionType: 'online_text_entry',
        submittedAt: '2025-11-03T00:00:00Z',
      },
    },
  ]

  it('renders no peer reviews message when assessment requests are null', () => {
    const mockOnChange = vi.fn()
    render(
      <PeerReviewSelector
        assessmentRequests={null as any}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
        requiredPeerReviewCount={0}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    expect(selector).toHaveAttribute('value', 'No peer reviews available')
  })

  it('shows correct count in label for second option selected', () => {
    const mockOnChange = vi.fn()
    render(
      <PeerReviewSelector
        assessmentRequests={mockAssessmentRequests}
        selectedIndex={1}
        onSelectionChange={mockOnChange}
        requiredPeerReviewCount={3}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    expect(selector).toHaveAttribute('value', 'Peer Review (2 of 3)')
  })

  it('calls onSelectionChange when selection changes', async () => {
    const mockOnChange = vi.fn()
    const user = userEvent.setup()
    render(
      <PeerReviewSelector
        assessmentRequests={mockAssessmentRequests}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
        requiredPeerReviewCount={3}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    const thirdOption = screen.getByText('Peer Review (3 of 3)')
    await user.click(thirdOption)

    expect(mockOnChange).toHaveBeenCalledWith(2)
  })

  it('groups assessments into ready to review and completed sections', async () => {
    const mockOnChange = vi.fn()
    const user = userEvent.setup()
    const mixedAssessments: AssessmentRequest[] = [
      {
        _id: 'ar-1',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-01T00:00:00Z',
        anonymousId: null,
        anonymizedUser: null,
        submission: {
          _id: 'sub-1',
          attempt: 1,
          body: '<p>Test submission 1</p>',
          submissionType: 'online_text_entry',
          submittedAt: '2025-11-01T00:00:00Z',
        },
      },
      {
        _id: 'ar-2',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-02T00:00:00Z',
        anonymousId: null,
        anonymizedUser: null,
        submission: {
          _id: 'sub-2',
          attempt: 1,
          body: '<p>Test submission 2</p>',
          submissionType: 'online_text_entry',
          submittedAt: '2025-11-02T00:00:00Z',
        },
      },
      {
        _id: 'ar-3',
        available: true,
        workflowState: 'completed',
        createdAt: '2025-11-03T00:00:00Z',
        anonymousId: null,
        anonymizedUser: null,
        submission: {
          _id: 'sub-3',
          attempt: 1,
          body: '<p>Test submission 3</p>',
          submissionType: 'online_text_entry',
          submittedAt: '2025-11-03T00:00:00Z',
        },
      },
    ]

    render(
      <PeerReviewSelector
        assessmentRequests={mixedAssessments}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
        requiredPeerReviewCount={3}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    expect(screen.getByText('Ready to Review')).toBeInTheDocument()
    expect(screen.getByText('Completed Peer Reviews')).toBeInTheDocument()
  })

  it('only shows ready to review group when no completed assessments', async () => {
    const mockOnChange = vi.fn()
    const user = userEvent.setup()

    render(
      <PeerReviewSelector
        assessmentRequests={mockAssessmentRequests}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
        requiredPeerReviewCount={3}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    expect(screen.getByText('Ready to Review')).toBeInTheDocument()
    expect(screen.queryByText('Completed Peer Reviews')).not.toBeInTheDocument()
  })

  it('filters out unavailable items and shows only available in selector with correct numbering when item is unavailable', async () => {
    const mockOnChange = vi.fn()
    const user = userEvent.setup()
    const assessmentsWithUnavailableFirst: AssessmentRequest[] = [
      {
        _id: 'ar-1',
        available: false,
        workflowState: 'assigned',
        createdAt: '2025-11-01T00:00:00Z',
        anonymousId: null,
        anonymizedUser: null,
        submission: {
          _id: 'sub-1',
          attempt: 1,
          body: '<p>Test submission 1</p>',
          submissionType: 'online_text_entry',
          submittedAt: null,
        },
      },
      {
        _id: 'ar-2',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-02T00:00:00Z',
        anonymousId: null,
        anonymizedUser: null,
        submission: {
          _id: 'sub-2',
          attempt: 1,
          body: '<p>Test submission 2</p>',
          submissionType: 'online_text_entry',
          submittedAt: '2025-11-02T00:00:00Z',
        },
      },
      {
        _id: 'ar-3',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-03T00:00:00Z',
        anonymousId: null,
        anonymizedUser: null,
        submission: {
          _id: 'sub-3',
          attempt: 1,
          body: '<p>Test submission 3</p>',
          submissionType: 'online_text_entry',
          submittedAt: '2025-11-03T00:00:00Z',
        },
      },
    ]

    render(
      <PeerReviewSelector
        assessmentRequests={assessmentsWithUnavailableFirst}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
        requiredPeerReviewCount={2}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    expect(screen.getByText('Peer Review (1 of 2)')).toBeInTheDocument()
    expect(screen.getByText('Peer Review (2 of 2)')).toBeInTheDocument()
    expect(screen.queryByText('Peer Review (1 of 3)')).not.toBeInTheDocument()
  })

  describe('Unavailable peer reviews', () => {
    it('shows "Not Yet Available" section when there are fewer available than required', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()
      const oneAvailableAssessment: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: {
            _id: '1',
            displayName: 'Student 1',
          },
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={oneAvailableAssessment}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.getByText('Not Yet Available')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (2 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (3 of 3)')).toBeInTheDocument()
    })

    it('shows correct numbering for unavailable reviews', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()
      const oneAvailableAssessment: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: {
            _id: '1',
            displayName: 'Student 1',
          },
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={oneAvailableAssessment}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.getByText('Peer Review (1 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (2 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (3 of 3)')).toBeInTheDocument()
    })

    it('calls onSelectionChange with correct index when unavailable option is selected', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()
      const oneAvailableAssessment: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: {
            _id: '1',
            displayName: 'Student 1',
          },
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={oneAvailableAssessment}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      const unavailableOption = screen.getByText('Peer Review (2 of 3)')
      await user.click(unavailableOption)

      expect(mockOnChange).toHaveBeenCalledWith(1)
    })

    it('shows all unavailable when no assessments are allocated', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()

      render(
        <PeerReviewSelector
          assessmentRequests={[]}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.getByText('Not Yet Available')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (1 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (2 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (3 of 3)')).toBeInTheDocument()
    })

    it('does not show "Not Yet Available" section when all required reviews are available', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()

      render(
        <PeerReviewSelector
          assessmentRequests={mockAssessmentRequests}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.queryByText('Not Yet Available')).not.toBeInTheDocument()
    })

    it('displays unavailable option with correct value when unavailable is selected', () => {
      const mockOnChange = vi.fn()
      const oneAvailableAssessment: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: {
            _id: '1',
            displayName: 'Student 1',
          },
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={oneAvailableAssessment}
          selectedIndex={1}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      expect(selector).toHaveAttribute('value', 'Peer Review (2 of 3)')
    })
  })

  describe('Assessments without submissions', () => {
    it('shows assessment without submission in "Not Yet Available" group', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()
      const assessmentsWithoutSubmission: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
        {
          _id: 'ar-2',
          available: false,
          workflowState: 'assigned',
          createdAt: '2025-11-02T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-2',
            attempt: 0,
            body: null,
            submissionType: 'online_text_entry',
            submittedAt: null,
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={assessmentsWithoutSubmission}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={2}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.getByText('Ready to Review')).toBeInTheDocument()
      expect(screen.getByText('Not Yet Available')).toBeInTheDocument()
    })

    it('groups assessment without submission with unallocated reviews in "Not Yet Available"', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()
      const assessmentsWithoutSubmission: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: false,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-1',
            attempt: 0,
            body: null,
            submissionType: 'online_text_entry',
            submittedAt: null,
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={assessmentsWithoutSubmission}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.getByText('Not Yet Available')).toBeInTheDocument()
      // Should have 3 items: 1 without submission + 2 unallocated
      expect(screen.getByText('Peer Review (1 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (2 of 3)')).toBeInTheDocument()
      expect(screen.getByText('Peer Review (3 of 3)')).toBeInTheDocument()
    })

    it('displays assessment without submission with correct numbering', async () => {
      const mockOnChange = vi.fn()
      const user = userEvent.setup()
      const assessmentsWithMixedStatus: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
        {
          _id: 'ar-2',
          available: false,
          workflowState: 'assigned',
          createdAt: '2025-11-02T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-2',
            attempt: 0,
            body: null,
            submissionType: 'online_text_entry',
            submittedAt: null,
          },
        },
        {
          _id: 'ar-3',
          available: true,
          workflowState: 'completed',
          createdAt: '2025-11-03T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-3',
            attempt: 1,
            body: '<p>Test submission 3</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-03T00:00:00Z',
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={assessmentsWithMixedStatus}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={3}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      await user.click(selector)

      expect(screen.getByText('Ready to Review')).toBeInTheDocument()
      expect(screen.getByText('Completed Peer Reviews')).toBeInTheDocument()
      expect(screen.getByText('Not Yet Available')).toBeInTheDocument()

      // Check that numbering is correct
      const options = screen.getAllByText(/Peer Review \(\d+ of 3\)/)
      expect(options).toHaveLength(3)
    })

    it('includes all assessments regardless of available status', () => {
      const mockOnChange = vi.fn()
      const assessmentsIncludingUnavailable: AssessmentRequest[] = [
        {
          _id: 'ar-1',
          available: true,
          workflowState: 'assigned',
          createdAt: '2025-11-01T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-1',
            attempt: 1,
            body: '<p>Test submission 1</p>',
            submissionType: 'online_text_entry',
            submittedAt: '2025-11-01T00:00:00Z',
          },
        },
        {
          _id: 'ar-2',
          available: false,
          workflowState: 'assigned',
          createdAt: '2025-11-02T00:00:00Z',
          anonymousId: null,
          anonymizedUser: null,
          submission: {
            _id: 'sub-2',
            attempt: 0,
            body: null,
            submissionType: 'online_text_entry',
            submittedAt: null,
          },
        },
      ]

      render(
        <PeerReviewSelector
          assessmentRequests={assessmentsIncludingUnavailable}
          selectedIndex={0}
          onSelectionChange={mockOnChange}
          requiredPeerReviewCount={2}
        />,
      )

      const selector = screen.getByTestId('peer-review-selector')
      // Both assessments should be available in the selector (showing "1 of 2" for first one)
      expect(selector).toHaveAttribute('value', 'Peer Review (1 of 2)')
    })
  })
})
