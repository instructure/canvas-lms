/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {act, render, screen, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import UserObservees, {type Observee} from '../UserObservees'

// Mock @instructure/ui-dialog to prevent FocusRegionManager issues
// Dialog uses FocusRegionManager which schedules RAF callbacks that can fire after
// test cleanup, causing "Argument appears to not be a ReactComponent" errors
vi.mock('@instructure/ui-dialog', () => ({
  Dialog: ({children, open}: {children: React.ReactNode; open?: boolean}) =>
    open !== false ? <div data-testid="mock-dialog">{children}</div> : null,
}))

// Mock @instructure/ui-overlays to prevent focus region management issues in tests
// The real Overlay uses FocusRegionManager which schedules RAF callbacks that can
// fire after test cleanup, causing "Argument appears to not be a ReactComponent" errors
vi.mock('@instructure/ui-overlays', () => ({
  Overlay: ({children, open}: {children: React.ReactNode; open: boolean}) =>
    open ? <div data-testid="mock-overlay">{children}</div> : null,
  Mask: ({children}: {children: React.ReactNode}) => <div data-testid="mock-mask">{children}</div>,
}))

// Mock flash alerts to prevent async DOM operations that can leak between tests
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn()),
  showFlashSuccess: vi.fn(() => vi.fn()),
}))

// Mock globalUtils to prevent actual navigation
vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

const server = setupServer()

const userId = '1'
const observees: Array<Observee> = [
  {
    id: '9',
    name: 'Forest Minish',
  },
  {
    id: '10',
    name: 'Link Minish',
  },
]
const GET_OBSERVEES_URI = `/api/v1/users/${userId}/observees`

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
        staleTime: 0,
      },
      mutations: {
        retry: false,
      },
    },
  })

const renderComponent = (queryClient: QueryClient) =>
  render(
    <QueryClientProvider client={queryClient}>
      <UserObservees userId={userId} />
    </QueryClientProvider>,
  )

describe('UserObservees', () => {
  let originalConfirm: typeof window.confirm

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    originalConfirm = window.confirm
  })

  beforeEach(() => {
    // Mock window.confirm for each test
    window.confirm = vi.fn().mockReturnValue(true)
  })

  afterEach(async () => {
    // Cleanup rendered components
    cleanup()
    // Reset server handlers
    server.resetHandlers()
    // Clear all mocks
    vi.clearAllMocks()
    // Allow pending microtasks to settle
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })
  })

  afterAll(() => {
    server.close()
    window.confirm = originalConfirm
  })

  describe('when no students are being observed', () => {
    it('should show the placeholder message', async () => {
      const queryClient = createQueryClient()
      server.use(
        http.get(GET_OBSERVEES_URI, () => {
          return HttpResponse.json([])
        }),
      )

      await act(async () => {
        renderComponent(queryClient)
      })

      const noStudentsMessage = await screen.findByText(content => {
        return content.trim() === 'No students being observed.'
      })
      expect(noStudentsMessage).toBeInTheDocument()
    })
  })

  describe('when failing to fetch observees', () => {
    it('should show the error message', async () => {
      const queryClient = createQueryClient()
      server.use(
        http.get(GET_OBSERVEES_URI, () => {
          return HttpResponse.json({error: 'Unknown error'}, {status: 500})
        }),
      )

      await act(async () => {
        renderComponent(queryClient)
      })

      const errorMessage = await screen.findByText('Failed to load students.')
      expect(errorMessage).toBeInTheDocument()
    })
  })

  describe('when observees are fetched successfully', () => {
    it('should show the list of observees', async () => {
      const queryClient = createQueryClient()
      server.use(
        http.get(GET_OBSERVEES_URI, () => {
          return HttpResponse.json(observees)
        }),
      )

      await act(async () => {
        renderComponent(queryClient)
      })

      for (const observee of observees) {
        const studentName = await screen.findByText(observee.name)
        expect(studentName).toBeInTheDocument()
      }
    })
  })

  describe('when pairing code is empty', () => {
    it('should show an error after the form is submitted', async () => {
      const queryClient = createQueryClient()
      const user = userEvent.setup()
      server.use(
        http.get(GET_OBSERVEES_URI, () => {
          return HttpResponse.json([])
        }),
      )

      await act(async () => {
        renderComponent(queryClient)
      })

      const submit = screen.getByLabelText('Student')
      await user.click(submit)

      const errorTexts = await screen.findAllByText('Invalid pairing code.')
      expect(errorTexts.length).toBeTruthy()
    })
  })
})
