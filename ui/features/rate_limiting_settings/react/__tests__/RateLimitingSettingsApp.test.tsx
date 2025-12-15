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
import RateLimitingSettingsApp from '../RateLimitingSettingsApp'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the flash alert
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

const server = setupServer()

// Mock the copy to clipboard button
vi.mock('@canvas/copy-to-clipboard-button', () => ({
  default: function MockCopyToClipboardButton(props: any) {
    return (
      <button
        onClick={() => navigator.clipboard?.writeText(props.value)}
        aria-label={props.screenReaderLabel}
        title={props.tooltipText}
      >
        Copy
      </button>
    )
  },
}))

beforeAll(() => {
  server.listen()
  // Mock clipboard API
  Object.assign(navigator, {
    clipboard: {
      writeText: vi.fn().mockResolvedValue(undefined),
    },
  })
  fakeENV.setup({ACCOUNT_ID: '1'})
})

afterAll(() => {
  server.close()
  fakeENV.teardown()
})

const mockRateLimitSettings = [
  {
    id: '1',
    identifier_type: 'product',
    identifier_value: 'partner-product-123',
    masked_identifier: 'part...123',
    display_name: 'Partner - Product 123',
    partner_name: 'Partner',
    product_name: 'Product 123',
    rate_limit: 1000,
    outflow_rate: 50,
    client_name: 'Test Partner Integration',
    comments: 'Test rate limit setting',
    truncated_comments: 'Test rate limit setting',
    created_at: '2023-01-01T00:00:00.000Z',
    updated_at: '2023-01-01T00:00:00.000Z',
    updated_by: 'Admin User',
  },
  {
    id: '2',
    identifier_type: 'product',
    identifier_value: 'another-partner-tool',
    masked_identifier: 'ano...ool',
    display_name: 'Another Partner - Tool',
    partner_name: 'Another Partner',
    product_name: 'Tool',
    rate_limit: 500,
    outflow_rate: 25,
    client_name: 'Another Tool',
    comments: 'Another test setting',
    truncated_comments: 'Another test setting',
    created_at: '2023-01-02T00:00:00.000Z',
    updated_at: '2023-01-02T00:00:00.000Z',
    updated_by: 'Site Admin',
  },
]

// BookmarkedCollection returns the array directly
const mockApiResponse = mockRateLimitSettings

describe('RateLimitingSettingsApp', () => {
  beforeEach(() => {
    ;(showFlashAlert as any).mockClear()

    // Mock CSRF token meta tag
    const csrfMeta = document.createElement('meta')
    csrfMeta.name = 'csrf-token'
    csrfMeta.content = 'test-token'
    document.head.appendChild(csrfMeta)
  })

  afterEach(() => {
    server.resetHandlers()
    document.querySelectorAll('meta[name="csrf-token"]').forEach(meta => meta.remove())
  })

  describe('loading state', () => {
    it('shows loading spinner initially', () => {
      // Set up a handler that never resolves by using a delay longer than the test timeout
      server.use(
        http.get('/accounts/1/rate_limiting_settings', async () => {
          await new Promise(() => {}) // Never resolves
        }),
      )

      render(<RateLimitingSettingsApp />)

      expect(screen.getByTitle(/loading rate limiting settings/i)).toBeInTheDocument()
    })
  })

  describe('data fetching', () => {
    it('fetches and displays rate limit settings', async () => {
      server.use(
        http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.json(mockApiResponse)),
      )

      render(<RateLimitingSettingsApp />)

      await waitFor(() => {
        expect(screen.getByText('Test Partner Integration')).toBeInTheDocument()
      })

      expect(screen.getByText('Test Partner Integration')).toBeInTheDocument()
      expect(screen.getByText('Another Tool')).toBeInTheDocument()
      expect(screen.getByText('1000')).toBeInTheDocument()
      expect(screen.getByText('500')).toBeInTheDocument()
    })

    it('shows error message when fetch fails', async () => {
      server.use(http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.error()))

      render(<RateLimitingSettingsApp />)

      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'Failed to load rate limiting settings',
          type: 'error',
        })
      })
    })
  })

  describe('empty state', () => {
    it('shows empty message when no settings exist', async () => {
      server.use(http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.json([])))

      render(<RateLimitingSettingsApp />)

      await waitFor(() => {
        expect(screen.getByText(/no rate limiting settings found/i)).toBeInTheDocument()
      })
    })
  })

  describe('create rate limit button', () => {
    it('opens create modal when clicked', async () => {
      server.use(
        http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.json(mockApiResponse)),
      )

      render(<RateLimitingSettingsApp />)

      await waitFor(() => {
        expect(screen.getByText('Test Partner Integration')).toBeInTheDocument()
      })

      const createButton = screen.getByRole('button', {name: /create rate limit/i})
      await userEvent.click(createButton)

      expect(screen.getByRole('dialog', {name: /create rate limit/i})).toBeInTheDocument()
    })
  })

  describe('actions menu', () => {
    it('shows edit and delete options for each setting', async () => {
      server.use(
        http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.json(mockApiResponse)),
      )

      render(<RateLimitingSettingsApp />)

      // Wait for the table content to appear
      await waitFor(() => {
        expect(screen.getByText('Test Partner Integration')).toBeInTheDocument()
        expect(screen.getByText('Another Tool')).toBeInTheDocument()
      })

      // Look for action buttons using a more direct approach
      const actionButtons = screen.getAllByRole('button', {name: /actions for/i})
      expect(actionButtons).toHaveLength(2)

      await userEvent.click(actionButtons[0])

      expect(screen.getByRole('menuitem', {name: /edit/i})).toBeInTheDocument()
      expect(screen.getByRole('menuitem', {name: /delete/i})).toBeInTheDocument()
    })
  })

  describe('delete functionality', () => {
    it('deletes a rate limit setting when confirmed', async () => {
      let deleteCallReceived = false
      server.use(
        http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.json(mockApiResponse)),
        http.delete('/accounts/1/rate_limiting_settings/1', () => {
          deleteCallReceived = true
          return HttpResponse.json({})
        }),
      )

      // Mock window.confirm
      const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true)

      render(<RateLimitingSettingsApp />)

      await waitFor(() => {
        expect(screen.getByText('Test Partner Integration')).toBeInTheDocument()
      })

      const actionButtons = screen.getAllByRole('button', {name: /actions for/i})
      await userEvent.click(actionButtons[0])

      const deleteButton = screen.getByRole('menuitem', {name: /delete/i})
      await userEvent.click(deleteButton)

      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'Rate limit setting deleted',
          type: 'success',
        })
      })

      expect(deleteCallReceived).toBe(true)
      confirmSpy.mockRestore()
    })

    it('does not delete when user cancels', async () => {
      let deleteCallReceived = false
      server.use(
        http.get('/accounts/1/rate_limiting_settings', () => HttpResponse.json(mockApiResponse)),
        http.delete('/accounts/1/rate_limiting_settings/1', () => {
          deleteCallReceived = true
          return HttpResponse.json({})
        }),
      )

      // Mock window.confirm to return false
      const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(false)

      render(<RateLimitingSettingsApp />)

      await waitFor(() => {
        expect(screen.getByText('Test Partner Integration')).toBeInTheDocument()
      })

      const actionButtons = screen.getAllByRole('button', {name: /actions for/i})
      await userEvent.click(actionButtons[0])

      const deleteButton = screen.getByRole('menuitem', {name: /delete/i})
      await userEvent.click(deleteButton)

      // Delete should not have been called since user cancelled
      expect(deleteCallReceived).toBe(false)

      confirmSpy.mockRestore()
    })
  })
})
