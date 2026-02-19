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
import {PeerReviewWidget} from '../PeerReviewWidget'

vi.mock('../PeerReviewConfigurationTray', () => ({
  PeerReviewConfigurationTray: ({
    isTrayOpen,
    closeTray,
  }: {
    isTrayOpen: boolean
    closeTray: () => void
  }) => (
    <div data-testid="mock-config-tray">
      {isTrayOpen && (
        <>
          <div>Config Tray Content</div>
          <button onClick={closeTray}>Close Tray</button>
        </>
      )}
    </div>
  ),
}))

vi.mock('../PeerReviewAllocationRulesTray', () => ({
  default: ({isTrayOpen, closeTray}: {isTrayOpen: boolean; closeTray: () => void}) => (
    <div data-testid="mock-allocation-tray">
      {isTrayOpen && (
        <>
          <div>Allocation Tray Content</div>
          <button onClick={closeTray}>Close Allocation Tray</button>
        </>
      )}
    </div>
  ),
}))

describe('PeerReviewWidget', () => {
  const defaultProps = {
    assignmentId: '123',
    courseId: '456',
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    ENV.CAN_EDIT_ASSIGNMENTS = false
  })

  afterEach(() => {
    window.history.replaceState({}, '', window.location.pathname)
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
        <PeerReviewWidget {...defaultProps} {...props} />
      </MockedQueryClientProvider>,
    )
  }

  it('renders the widget', () => {
    renderWithQueryClient()
    expect(screen.getByText('Peer Review')).toBeInTheDocument()
  })

  it('renders the peer review icon and text', () => {
    renderWithQueryClient()
    expect(screen.getByText('Peer Review')).toBeInTheDocument()
  })

  it('renders the View Configuration button', () => {
    renderWithQueryClient()
    const button = screen.getByTestId('view-configuration-button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('View Configuration')
  })

  it('renders the Allocate Peer Reviews button', () => {
    renderWithQueryClient()
    const button = screen.getByTestId('allocate-peer-reviews-button')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('Allocate Peer Reviews')
  })

  it('renders all buttons', () => {
    renderWithQueryClient()
    expect(screen.getByTestId('view-configuration-button')).toBeInTheDocument()
    expect(screen.getByTestId('allocate-peer-reviews-button')).toBeInTheDocument()
  })

  describe('Configuration Tray', () => {
    it('opens configuration tray when View Configuration button is clicked', async () => {
      renderWithQueryClient()

      expect(screen.queryByText('Config Tray Content')).not.toBeInTheDocument()

      const viewConfigButton = screen.getByTestId('view-configuration-button')
      await user.click(viewConfigButton)

      expect(screen.getByText('Config Tray Content')).toBeInTheDocument()
    })

    it('closes configuration tray when close is triggered', async () => {
      renderWithQueryClient()

      const viewConfigButton = screen.getByTestId('view-configuration-button')
      await user.click(viewConfigButton)

      expect(screen.getByText('Config Tray Content')).toBeInTheDocument()

      const closeButton = screen.getByText('Close Tray')
      await user.click(closeButton)

      expect(screen.queryByText('Config Tray Content')).not.toBeInTheDocument()
    })

    it('tray is initially closed', () => {
      renderWithQueryClient()
      expect(screen.queryByText('Config Tray Content')).not.toBeInTheDocument()
    })
  })

  describe('Allocation Tray', () => {
    it('opens allocation tray when Allocate Peer Reviews button is clicked', async () => {
      renderWithQueryClient()

      expect(screen.queryByText('Allocation Tray Content')).not.toBeInTheDocument()

      const allocateButton = screen.getByTestId('allocate-peer-reviews-button')
      await user.click(allocateButton)

      expect(screen.getByText('Allocation Tray Content')).toBeInTheDocument()
    })

    it('closes allocation tray when close is triggered', async () => {
      renderWithQueryClient()

      const allocateButton = screen.getByTestId('allocate-peer-reviews-button')
      await user.click(allocateButton)

      expect(screen.getByText('Allocation Tray Content')).toBeInTheDocument()

      const closeButton = screen.getByText('Close Allocation Tray')
      await user.click(closeButton)

      expect(screen.queryByText('Allocation Tray Content')).not.toBeInTheDocument()
    })

    it('tray is initially closed', () => {
      renderWithQueryClient()
      expect(screen.queryByText('Allocation Tray Content')).not.toBeInTheDocument()
    })

    it('passes canEdit from ENV.CAN_EDIT_ASSIGNMENTS to allocation tray', async () => {
      ENV.CAN_EDIT_ASSIGNMENTS = true

      renderWithQueryClient()

      const allocateButton = screen.getByTestId('allocate-peer-reviews-button')
      await user.click(allocateButton)

      expect(screen.getByText('Allocation Tray Content')).toBeInTheDocument()
    })

    it('automatically opens allocation tray when open_allocation_tray URL parameter is true', () => {
      window.history.replaceState({}, '', '?open_allocation_tray=true')

      renderWithQueryClient()

      expect(screen.getByText('Allocation Tray Content')).toBeInTheDocument()
    })

    it('does not automatically open allocation tray when URL parameter is false', () => {
      window.history.replaceState({}, '', '?open_allocation_tray=false')

      renderWithQueryClient()

      expect(screen.queryByText('Allocation Tray Content')).not.toBeInTheDocument()
    })

    it('does not automatically open allocation tray when URL parameter is missing', () => {
      renderWithQueryClient()

      expect(screen.queryByText('Allocation Tray Content')).not.toBeInTheDocument()
    })
  })

  describe('Tray Interaction', () => {
    it('closes configuration tray when allocation tray is opened', async () => {
      renderWithQueryClient()

      const viewConfigButton = screen.getByTestId('view-configuration-button')
      await user.click(viewConfigButton)

      expect(screen.getByText('Config Tray Content')).toBeInTheDocument()

      const allocateButton = screen.getByTestId('allocate-peer-reviews-button')
      await user.click(allocateButton)

      expect(screen.queryByText('Config Tray Content')).not.toBeInTheDocument()
      expect(screen.getByText('Allocation Tray Content')).toBeInTheDocument()
    })

    it('closes allocation tray when configuration tray is opened', async () => {
      renderWithQueryClient()

      const allocateButton = screen.getByTestId('allocate-peer-reviews-button')
      await user.click(allocateButton)

      expect(screen.getByText('Allocation Tray Content')).toBeInTheDocument()

      const viewConfigButton = screen.getByTestId('view-configuration-button')
      await user.click(viewConfigButton)

      expect(screen.queryByText('Allocation Tray Content')).not.toBeInTheDocument()
      expect(screen.getByText('Config Tray Content')).toBeInTheDocument()
    })
  })
})
