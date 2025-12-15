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

describe('PeerReviewWidget', () => {
  const defaultProps = {
    assignmentId: '123',
    courseId: '456',
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
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
})
