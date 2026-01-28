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

import {assignLocation} from '@canvas/util/globalUtils'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {act, render, screen, waitFor, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import UserObservees, {type Observee} from '../UserObservees'

// Mock globalUtils to prevent actual navigation
vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

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

const mockShowFlashSuccess = vi.mocked(showFlashSuccess)
const mockShowFlashError = vi.mocked(showFlashError)

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
const newObservee: Observee = {
  id: '11',
  name: 'Zelda Minish',
}
const GET_OBSERVEES_URI = `/api/v1/users/${userId}/observees`
const POST_OBSERVEES_URI = `/api/v1/users/${userId}/observees`
const createDeleteObserveeUri = (id: string) => `/api/v1/users/self/observees/${id}`

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

describe('UserObservees Mutations', () => {
  let confirmMock: ReturnType<typeof vi.fn>
  let originalConfirm: typeof window.confirm

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    originalConfirm = window.confirm
  })

  beforeEach(() => {
    confirmMock = vi.fn().mockReturnValue(true)
    window.confirm = confirmMock
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

  describe('when adding a student as observee', () => {
    describe('and redirect is needed', () => {
      it('should show the confirm dialog and redirect', async () => {
        const queryClient = createQueryClient()
        const user = userEvent.setup()
        const redirectUrl = 'http://redirect-to.com'

        server.use(
          http.get(GET_OBSERVEES_URI, () => {
            return HttpResponse.json([])
          }),
          http.post(POST_OBSERVEES_URI, () => {
            return HttpResponse.json({...newObservee, redirect: redirectUrl})
          }),
        )

        await act(async () => {
          renderComponent(queryClient)
        })

        // Wait for initial load
        await screen.findByText('No students being observed.')

        const pairingCode = screen.getByLabelText('Student Pairing Code *')
        const submit = screen.getByLabelText('Student')

        await user.type(pairingCode, '123456')
        await user.click(submit)

        await waitFor(() => {
          expect(confirmMock).toHaveBeenCalled()
        })

        await waitFor(() => {
          expect(assignLocation).toHaveBeenCalledWith(redirectUrl)
        })
      })
    })

    describe('and no redirect needed', () => {
      it('should show the student in the list and trigger success banner', async () => {
        const queryClient = createQueryClient()
        const user = userEvent.setup()
        let requestCount = 0

        server.use(
          http.get(GET_OBSERVEES_URI, () => {
            requestCount++
            // First request returns empty, subsequent ones return the new observee
            if (requestCount === 1) {
              return HttpResponse.json([])
            }
            return HttpResponse.json([newObservee])
          }),
          http.post(POST_OBSERVEES_URI, () => {
            return HttpResponse.json(newObservee)
          }),
        )

        await act(async () => {
          renderComponent(queryClient)
        })

        // Wait for initial load
        await screen.findByText('No students being observed.')

        const pairingCode = screen.getByLabelText('Student Pairing Code *')
        const submit = screen.getByLabelText('Student')

        await user.type(pairingCode, '123456')
        await user.click(submit)

        // Wait for success flash to be called
        await waitFor(() => {
          expect(mockShowFlashSuccess).toHaveBeenCalledWith(`Now observing ${newObservee.name}.`)
        })

        // Verify the student is shown after refetch
        const observee = await screen.findByText(newObservee.name)
        expect(observee).toBeInTheDocument()
      })
    })

    describe('and the request failed', () => {
      it('should trigger an error banner', async () => {
        const queryClient = createQueryClient()
        const user = userEvent.setup()

        server.use(
          http.get(GET_OBSERVEES_URI, () => {
            return HttpResponse.json([])
          }),
          http.post(POST_OBSERVEES_URI, () => {
            return HttpResponse.json({error: 'Invalid'}, {status: 500})
          }),
        )

        await act(async () => {
          renderComponent(queryClient)
        })

        // Wait for initial load
        await screen.findByText('No students being observed.')

        const pairingCode = screen.getByLabelText('Student Pairing Code *')
        const submit = screen.getByLabelText('Student')

        await user.type(pairingCode, '123456')
        await user.click(submit)

        // Wait for error flash to be called
        await waitFor(() => {
          expect(mockShowFlashError).toHaveBeenCalledWith('Invalid pairing code.')
        })
      })
    })
  })

  describe('when removing an observee', () => {
    describe('and the request was successful', () => {
      it('should trigger success banner and remove from list', async () => {
        const queryClient = createQueryClient()
        const user = userEvent.setup()
        const [observeeToDelete, ...remainingObservees] = observees
        let deleteRequested = false

        server.use(
          http.get(GET_OBSERVEES_URI, () => {
            if (deleteRequested) {
              return HttpResponse.json(remainingObservees)
            }
            return HttpResponse.json(observees)
          }),
          http.delete(createDeleteObserveeUri(observeeToDelete.id), () => {
            deleteRequested = true
            return HttpResponse.json(observeeToDelete)
          }),
        )

        await act(async () => {
          renderComponent(queryClient)
        })

        // Wait for observees to load
        const removeButton = await screen.findByLabelText(`Remove ${observeeToDelete.name}`)
        await user.click(removeButton)

        // Wait for success flash to be called
        await waitFor(() => {
          expect(mockShowFlashSuccess).toHaveBeenCalledWith(
            `No longer observing ${observeeToDelete.name}.`,
          )
        })

        // Verify the student is removed after refetch
        await waitFor(() => {
          const observee = screen.queryByText(observeeToDelete.name)
          expect(observee).not.toBeInTheDocument()
        })
      })
    })

    describe('and the request failed', () => {
      it('should trigger an error banner', async () => {
        const queryClient = createQueryClient()
        const user = userEvent.setup()
        const [observeeToDelete] = observees

        server.use(
          http.get(GET_OBSERVEES_URI, () => {
            return HttpResponse.json(observees)
          }),
          http.delete(createDeleteObserveeUri(observeeToDelete.id), () => {
            return HttpResponse.json({error: 'Failed'}, {status: 500})
          }),
        )

        await act(async () => {
          renderComponent(queryClient)
        })

        // Wait for observees to load
        const removeButton = await screen.findByLabelText(`Remove ${observeeToDelete.name}`)
        await user.click(removeButton)

        // Wait for error flash to be called
        await waitFor(() => {
          expect(mockShowFlashError).toHaveBeenCalledWith('Failed to remove student.')
        })
      })
    })
  })
})
