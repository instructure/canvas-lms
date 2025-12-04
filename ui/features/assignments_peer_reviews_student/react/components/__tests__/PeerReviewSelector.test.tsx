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
import type {AssessmentRequest} from '../../hooks/useAssignmentQuery'

describe('PeerReviewSelector', () => {
  const mockAssessmentRequests: AssessmentRequest[] = [
    {
      _id: 'ar-1',
      available: true,
      workflowState: 'assigned',
      createdAt: '2025-11-01T00:00:00Z',
    },
    {
      _id: 'ar-2',
      available: true,
      workflowState: 'assigned',
      createdAt: '2025-11-02T00:00:00Z',
    },
    {
      _id: 'ar-3',
      available: true,
      workflowState: 'assigned',
      createdAt: '2025-11-03T00:00:00Z',
    },
  ]

  it('renders no peer reviews message when assessment requests are null', () => {
    const mockOnChange = jest.fn()
    render(
      <PeerReviewSelector
        assessmentRequests={null as any}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    expect(selector).toHaveAttribute('value', 'No peer reviews available')
  })

  it('shows correct count in label for second option selected', () => {
    const mockOnChange = jest.fn()
    render(
      <PeerReviewSelector
        assessmentRequests={mockAssessmentRequests}
        selectedIndex={1}
        onSelectionChange={mockOnChange}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    expect(selector).toHaveAttribute('value', 'Peer Review (2 of 3)')
  })

  it('calls onSelectionChange when selection changes', async () => {
    const mockOnChange = jest.fn()
    const user = userEvent.setup()
    render(
      <PeerReviewSelector
        assessmentRequests={mockAssessmentRequests}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    const thirdOption = screen.getByText('Peer Review (3 of 3)')
    await user.click(thirdOption)

    expect(mockOnChange).toHaveBeenCalledWith(2)
  })

  it('groups assessments into ready to review and completed sections', async () => {
    const mockOnChange = jest.fn()
    const user = userEvent.setup()
    const mixedAssessments: AssessmentRequest[] = [
      {
        _id: 'ar-1',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-01T00:00:00Z',
      },
      {
        _id: 'ar-2',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-02T00:00:00Z',
      },
      {
        _id: 'ar-3',
        available: true,
        workflowState: 'completed',
        createdAt: '2025-11-03T00:00:00Z',
      },
    ]

    render(
      <PeerReviewSelector
        assessmentRequests={mixedAssessments}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    expect(screen.getByText('Ready to Review')).toBeInTheDocument()
    expect(screen.getByText('Completed Peer Reviews')).toBeInTheDocument()
  })

  it('only shows ready to review group when no completed assessments', async () => {
    const mockOnChange = jest.fn()
    const user = userEvent.setup()

    render(
      <PeerReviewSelector
        assessmentRequests={mockAssessmentRequests}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    expect(screen.getByText('Ready to Review')).toBeInTheDocument()
    expect(screen.queryByText('Completed Peer Reviews')).not.toBeInTheDocument()
  })

  it('filters out unavailable items and shows only available in selector with correct numbering when item is unavailable', async () => {
    const mockOnChange = jest.fn()
    const user = userEvent.setup()
    const assessmentsWithUnavailableFirst: AssessmentRequest[] = [
      {
        _id: 'ar-1',
        available: false,
        workflowState: 'assigned',
        createdAt: '2025-11-01T00:00:00Z',
      },
      {
        _id: 'ar-2',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-02T00:00:00Z',
      },
      {
        _id: 'ar-3',
        available: true,
        workflowState: 'assigned',
        createdAt: '2025-11-03T00:00:00Z',
      },
    ]

    render(
      <PeerReviewSelector
        assessmentRequests={assessmentsWithUnavailableFirst}
        selectedIndex={0}
        onSelectionChange={mockOnChange}
      />,
    )

    const selector = screen.getByTestId('peer-review-selector')
    await user.click(selector)

    expect(screen.getByText('Peer Review (1 of 2)')).toBeInTheDocument()
    expect(screen.getByText('Peer Review (2 of 2)')).toBeInTheDocument()
    expect(screen.queryByText('Peer Review (1 of 3)')).not.toBeInTheDocument()
  })
})
