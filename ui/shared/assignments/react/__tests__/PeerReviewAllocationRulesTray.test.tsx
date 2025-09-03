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
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import PeerReviewAllocationRulesTray from '../PeerReviewAllocationRulesTray'

jest.mock('../images/pandasBalloon.svg', () => 'mock-pandas-balloon.svg')
jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

describe('PeerReviewAllocationRulesTray', () => {
  const defaultProps = {
    assignmentId: '456',
    isTrayOpen: true,
    closeTray: jest.fn(),
    canEdit: false,
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    jest.clearAllMocks()
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

  describe('Tray visibility', () => {
    it('renders the tray when isTrayOpen is true', () => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()
      expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
    })

    it('does not render tray content when isTrayOpen is false', () => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} isTrayOpen={false} />)

      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()
      expect(screen.queryByText('Allocation Rules')).not.toBeInTheDocument()
    })
  })

  describe('Header section', () => {
    beforeEach(() => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
    })

    it('displays the correct heading', () => {
      expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
    })

    it('calls closeTray when close button is clicked', async () => {
      const closeButtonWrapper = screen.getByTestId('allocation-rules-tray-close-button')
      const closeButton = closeButtonWrapper.querySelector('button')

      if (closeButton) {
        await user.click(closeButton)
      }

      expect(defaultProps.closeTray).toHaveBeenCalledTimes(1)
    })
  })

  describe('Navigation section', () => {
    beforeEach(() => {
      ENV.COURSE_ID = '1'
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
    })

    it('displays navigation text', () => {
      expect(screen.getByText(/For peer review configuration return to/)).toBeInTheDocument()
    })

    it('renders Edit Assignment link with correct href', () => {
      const editLink = screen.getByText('Edit Assignment')
      expect(editLink).toBeInTheDocument()
      expect(editLink.closest('a')).toHaveAttribute(
        'href',
        `/courses/${ENV.COURSE_ID}/assignments/${defaultProps.assignmentId}/edit?scrollTo=assignment_peer_reviews_fields`,
      )
    })
  })

  describe('Add Rule section', () => {
    beforeEach(() => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
    })

    it('renders the Add Rule button if canEdit is true', () => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} canEdit={true} />)
      const addRuleButton = screen.getByText('+ Rule')
      expect(addRuleButton).toBeInTheDocument()
      expect(addRuleButton.closest('button')).toBeInTheDocument()
    })

    it('Add Rule button is not rendered when canEdit is false', () => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
      const addRuleButton = screen.queryByText('+ Rule')
      expect(addRuleButton).not.toBeInTheDocument()
    })
  })

  // TODO [EGG-1625]: Unskip when rules are fetched
  describe.skip('Empty state', () => {
    beforeEach(() => {
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
    })

    it('displays empty state when no rules exist', () => {
      expect(screen.getByText('Create New Rules')).toBeInTheDocument()
    })

    it('displays empty state image', () => {
      const image = screen.getByAltText('Pandas Balloon')
      expect(image).toBeInTheDocument()
      expect(image).toHaveAttribute('src', 'mock-pandas-balloon.svg')
    })

    it('displays descriptive text about allocation', () => {
      expect(
        screen.getByText(/Allocation of peer reviews happens behind the scenes/),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/You can create rules that support your learning goals/),
      ).toBeInTheDocument()
    })
  })
})
