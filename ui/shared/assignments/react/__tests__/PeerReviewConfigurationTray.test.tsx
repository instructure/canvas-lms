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
import {PeerReviewConfigurationTray} from '../PeerReviewConfigurationTray'
import {usePeerReviewConfiguration} from '../../graphql/hooks/usePeerReviewConfiguration'

vi.mock('../../graphql/hooks/usePeerReviewConfiguration')

const mockUsePeerReviewConfiguration = usePeerReviewConfiguration as ReturnType<typeof vi.fn>

const mockConfig = {
  hasGroupCategory: false,
  peerReviews: {
    acrossSections: true,
    anonymousReviews: false,
    count: 5,
    submissionRequired: true,
    intraReviews: false,
  },
  peerReviewSubAssignment: {
    pointsPossible: 50,
  },
  loading: false,
  error: null,
}

const mockGroupConfig = {
  hasGroupCategory: true,
  peerReviews: {
    acrossSections: false,
    anonymousReviews: true,
    count: 3,
    submissionRequired: false,
    intraReviews: true,
  },
  peerReviewSubAssignment: {
    pointsPossible: 30,
  },
  loading: false,
  error: null,
}

describe('PeerReviewConfigurationTray', () => {
  const defaultProps = {
    assignmentId: '123',
    isTrayOpen: true,
    closeTray: vi.fn(),
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    vi.clearAllMocks()
  })

  const renderWithQueryClient = (props = {}) => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return render(
      <MockedQueryClientProvider client={queryClient}>
        <PeerReviewConfigurationTray {...defaultProps} {...props} />
      </MockedQueryClientProvider>,
    )
  }

  describe('Tray visibility', () => {
    it('renders the tray when isTrayOpen is true', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockConfig)
      renderWithQueryClient()
      expect(screen.getByTestId('peer-review-configuration-tray')).toBeInTheDocument()
    })

    it('displays tray title', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockConfig)
      renderWithQueryClient()
      expect(screen.getByText('Peer Review')).toBeInTheDocument()
    })

    it('renders close button', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockConfig)
      renderWithQueryClient()
      expect(screen.getByTestId('peer-review-config-tray-close-button')).toBeInTheDocument()
    })

    it('calls closeTray when close button is clicked', async () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockConfig)
      const closeTray = vi.fn()
      renderWithQueryClient({closeTray})

      const closeButton = screen
        .getByTestId('peer-review-config-tray-close-button')
        .querySelector('button')
      expect(closeButton).toBeTruthy()
      await user.click(closeButton!)

      expect(closeTray).toHaveBeenCalled()
    })
  })

  describe('Loading state', () => {
    it('displays loading spinner when data is loading', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        hasGroupCategory: false,
        peerReviews: null,
        peerReviewSubAssignment: null,
        loading: true,
        error: null,
      })

      renderWithQueryClient()
      expect(screen.getByTestId('peer-review-config-loading-spinner')).toBeInTheDocument()
    })

    it('does not display configuration rows when loading', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        hasGroupCategory: false,
        peerReviews: null,
        peerReviewSubAssignment: null,
        loading: true,
        error: null,
      })

      renderWithQueryClient()
      expect(screen.queryByText('Reviews Required')).not.toBeInTheDocument()
    })
  })

  describe('Error state', () => {
    it('displays error alert when there is an error', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        hasGroupCategory: false,
        peerReviews: null,
        peerReviewSubAssignment: null,
        loading: false,
        error: new Error('Failed to load'),
      })

      renderWithQueryClient()
      expect(screen.getByTestId('peer-review-config-error-alert')).toBeInTheDocument()
      expect(
        screen.getByText('An error occurred while loading the peer review configuration'),
      ).toBeInTheDocument()
    })

    it('does not display configuration rows when there is an error', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        hasGroupCategory: false,
        peerReviews: null,
        peerReviewSubAssignment: null,
        loading: false,
        error: new Error('Failed to load'),
      })

      renderWithQueryClient()
      expect(screen.queryByText('Reviews Required')).not.toBeInTheDocument()
    })
  })

  describe('Null peer reviews state', () => {
    it('displays message when peerReviews is null', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        hasGroupCategory: false,
        peerReviews: null,
        peerReviewSubAssignment: mockConfig.peerReviewSubAssignment,
        loading: false,
        error: null,
      })

      renderWithQueryClient()
      expect(
        screen.getByText('This assignment is not configured for peer review'),
      ).toBeInTheDocument()
    })

    it('displays message when peerReviewSubAssignment is null', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        hasGroupCategory: false,
        peerReviews: mockConfig.peerReviews,
        peerReviewSubAssignment: null,
        loading: false,
        error: null,
      })

      renderWithQueryClient()
      expect(
        screen.getByText('This assignment is not configured for peer review'),
      ).toBeInTheDocument()
    })
  })

  describe('Configuration display', () => {
    it('displays all configuration fields for regular assignment', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockConfig)
      renderWithQueryClient()

      expect(screen.getByText('Reviews Required')).toBeInTheDocument()
      expect(screen.getByText('5')).toBeInTheDocument()

      expect(screen.getByText('Points Per Review')).toBeInTheDocument()
      expect(screen.getByText('10')).toBeInTheDocument()

      expect(screen.getByText('Total Points')).toBeInTheDocument()
      expect(screen.getByText('50')).toBeInTheDocument()

      expect(screen.getByText('Across Sections')).toBeInTheDocument()
      expect(screen.getByText('Allowed')).toBeInTheDocument()

      expect(screen.getByText('Submission Req')).toBeInTheDocument()
      expect(screen.getByText('Required')).toBeInTheDocument()

      expect(screen.getByText('Anonymity')).toBeInTheDocument()
      expect(screen.getByText('Not anonymous')).toBeInTheDocument()
    })

    it('does not display "Within Groups" for non-group assignment', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockConfig)
      renderWithQueryClient()

      expect(screen.queryByText('Within Groups')).not.toBeInTheDocument()
    })

    it('displays "Within Groups" for group assignment', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockGroupConfig)
      renderWithQueryClient()

      expect(screen.getByText('Within Groups')).toBeInTheDocument()
      expect(screen.getAllByText('Allowed')).toHaveLength(1)
    })

    it('displays correct values for group assignment configuration', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockGroupConfig)
      renderWithQueryClient()

      expect(screen.getByText('3')).toBeInTheDocument()
      expect(screen.getByText('10')).toBeInTheDocument()
      expect(screen.getByText('30')).toBeInTheDocument()
      expect(screen.getByText('Not allowed')).toBeInTheDocument()
      expect(screen.getByText('Not required')).toBeInTheDocument()
      expect(screen.getByText('Anonymous')).toBeInTheDocument()
    })

    it('handles zero total points', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        ...mockConfig,
        peerReviewSubAssignment: {
          pointsPossible: 0,
        },
      })
      renderWithQueryClient()

      expect(screen.getByText('Points Per Review')).toBeInTheDocument()
      const zeros = screen.getAllByText('0')
      expect(zeros.length).toBeGreaterThanOrEqual(2)
    })

    it('displays "Not allowed" when acrossSections is false', () => {
      mockUsePeerReviewConfiguration.mockReturnValue({
        ...mockConfig,
        peerReviews: {
          ...mockConfig.peerReviews,
          acrossSections: false,
        },
      })
      renderWithQueryClient()

      expect(screen.getByText('Across Sections')).toBeInTheDocument()
      expect(screen.getByText('Not allowed')).toBeInTheDocument()
    })

    it('displays "Allowed" when intraReviews is true for group assignment', () => {
      mockUsePeerReviewConfiguration.mockReturnValue(mockGroupConfig)
      renderWithQueryClient()

      expect(screen.getByText('Within Groups')).toBeInTheDocument()
      expect(screen.getByText('Allowed')).toBeInTheDocument()
    })
  })
})
