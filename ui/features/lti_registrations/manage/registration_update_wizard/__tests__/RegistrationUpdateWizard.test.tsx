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

import {render, screen, waitFor, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import {RegistrationUpdateWizard} from '../RegistrationUpdateWizard'
import {ZAccountId} from '../../model/AccountId'
import {ZLtiRegistrationUpdateRequestId} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {
  mockRegistration,
  mockToolConfiguration,
} from '../../dynamic_registration_wizard/__tests__/helpers'
import {LtiRegistrationUpdateRequest} from '../../model/lti_ims_registration/LtiRegistrationUpdateRequest'

// Mock dependencies
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

const server = setupServer()

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
        gcTime: 0,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('RegistrationUpdateWizard', () => {
  const defaultProps = {
    accountId: ZAccountId.parse('123'),
    registration: mockRegistration(),
    ltiRegistrationUpdateRequestId: ZLtiRegistrationUpdateRequestId.parse('update-123'),
    onDismiss: vi.fn(),
    onSuccess: vi.fn(),
  }

  const mockRegistrationUpdateRequest: () => LtiRegistrationUpdateRequest = () => ({
    id: ZLtiRegistrationUpdateRequestId.parse('update-123'),
    lti_registration_id: defaultProps.registration.id,
    status: 'pending' as const,
    internal_lti_configuration: mockToolConfiguration(),
    root_account_id: defaultProps.accountId,
    comment: 'Comment from tool',
  })

  const mockRegistrationWithConfig = mockRegistration({
    configuration: mockToolConfiguration({
      title: 'Test App',
      scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
    }),
  })

  beforeAll(() =>
    server.listen({
      onUnhandledRequest: 'error',
    }),
  )

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
  })

  afterAll(() => server.close())

  describe('error states', () => {
    it('renders error page when registration update request fails', async () => {
      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json({error: 'Failed to fetch update request'}, {status: 500})
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          // Accept any query parameters for this endpoint
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
      })
      expect(screen.getByText('Help us improve by telling us what happened')).toBeInTheDocument()
    })

    it('renders error page when registration with config fails', async () => {
      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json(mockRegistrationUpdateRequest())
          },
        ),
        http.get(
          `/api/v1/accounts/${defaultProps.accountId}/lti_registrations/${defaultProps.registration.id}`,
          () => {
            return HttpResponse.json({error: 'Failed to fetch registration'}, {status: 500})
          },
        ),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
      })
      expect(screen.getByText('Help us improve by telling us what happened')).toBeInTheDocument()
    })

    it('renders error page when both requests fail', async () => {
      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.accountId}/lti_registrations/${defaultProps.registration.id}/update_requests/${defaultProps.ltiRegistrationUpdateRequestId}`,
          () => {
            return HttpResponse.json({error: 'Server error'}, {status: 500})
          },
        ),
        http.get(
          `/api/v1/accounts/${defaultProps.accountId}/lti_registrations/${defaultProps.registration.id}`,
          () => {
            return HttpResponse.json({error: 'Server error'}, {status: 500})
          },
        ),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
      })
      expect(screen.getByText('Help us improve by telling us what happened')).toBeInTheDocument()
    })
  })

  describe('successful loading', () => {
    it('renders wizard with review step when both requests succeed', async () => {
      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json(mockRegistrationUpdateRequest())
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          // Accept any query parameters for this endpoint
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })

      expect(screen.getByLabelText('Installation Progress')).toBeInTheDocument()
    })

    it('displays progress bar with correct progress', async () => {
      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json(mockRegistrationUpdateRequest())
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        const progressBar = screen.getByLabelText('Installation Progress')
        expect(progressBar).toBeInTheDocument()
      })
    })
  })

  describe('header rendering', () => {
    it('renders header with close button during error', async () => {
      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.accountId}/lti_registrations/${defaultProps.registration.id}/update_requests/${defaultProps.ltiRegistrationUpdateRequestId}`,
          () => {
            return HttpResponse.json({error: 'Server error'}, {status: 500})
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          // Accept any query parameters for this endpoint
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /close/i})).toBeInTheDocument()
      })
    })

    it('renders header with close button during success', async () => {
      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json(mockRegistrationUpdateRequest())
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          // Accept any query parameters for this endpoint
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /close/i})).toBeInTheDocument()
        expect(screen.getByLabelText('Installation Progress')).toBeInTheDocument()
      })
    })
  })

  describe('wizard flow integration', () => {
    beforeEach(() => {
      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json(mockRegistrationUpdateRequest())
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )
    })

    it('starts with Review step and shows correct content', async () => {
      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })

      expect(screen.getByLabelText('Installation Progress')).toBeInTheDocument()
      expect(screen.getByText(/Accept All/i)).toBeInTheDocument()
      expect(screen.getByText(/Edit Updates/i)).toBeInTheDocument()
    })

    it('can navigate to permissions step via Edit Updates', async () => {
      const user = userEvent.setup()

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Edit Updates/i}))

      await waitFor(() => {
        expect(screen.getByText(/Permissions/i)).toBeInTheDocument()
      })

      expect(screen.getByText(/Next/i)).toBeInTheDocument()
      expect(screen.getByText(/Previous/i)).toBeInTheDocument()
    })

    it('can navigate through wizard steps', async () => {
      const user = userEvent.setup()

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Edit Updates/i}))

      await waitFor(() => {
        expect(screen.getByText(/Permissions/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Next/i}))

      await waitFor(() => {
        expect(screen.getByText(/Data Sharing/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Previous/i}))

      await waitFor(() => {
        expect(screen.getByText(/Permissions/i)).toBeInTheDocument()
      })
    })

    it('displays "Update Already Applied" message when status is applied', async () => {
      const appliedRequest = {
        ...mockRegistrationUpdateRequest(),
        status: 'applied' as const,
      }

      server.use(
        http.get(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId',
          () => {
            return HttpResponse.json(appliedRequest)
          },
        ),
        http.get('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json(mockRegistrationWithConfig)
        }),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Update Already Applied')).toBeInTheDocument()
      })

      expect(screen.getByText(/This update has already been applied/i)).toBeInTheDocument()

      const closeButtons = screen.queryAllByRole('button', {name: /close/i})
      expect(closeButtons.length).toBeGreaterThan(0)
    })

    it('applies updates when Accept All is clicked', async () => {
      const user = userEvent.setup()
      const {promise: requestPromise, resolve: resolveRequest} = createManualPromise()

      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId/apply',
          async () => {
            await requestPromise
            return HttpResponse.json({success: true})
          },
        ),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Accept All/i}))

      await waitFor(() => {
        expect(screen.getByText(/Applying registration update/i)).toBeInTheDocument()
      })

      resolveRequest(null)

      await waitFor(() => {
        expect(defaultProps.onSuccess).toHaveBeenCalled()
      })
    })

    it('handles apply failure gracefully', async () => {
      const user = userEvent.setup()
      const {promise: requestPromise, resolve: resolveRequest} = createManualPromise()

      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId/apply',
          async () => {
            await requestPromise
            return HttpResponse.json({error: 'Failed to apply'}, {status: 500})
          },
        ),
      )

      render(<RegistrationUpdateWizard {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Accept All/i}))

      await waitFor(() => {
        expect(screen.getByText(/Applying registration update/i)).toBeInTheDocument()
      })

      resolveRequest(null)

      await waitFor(
        () => {
          expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
        },
        {timeout: 5000},
      )
    })

    it('calls onDismiss when header close button is clicked', async () => {
      const user = userEvent.setup()
      const onDismissMock = vi.fn()

      render(<RegistrationUpdateWizard {...defaultProps} onDismiss={onDismissMock} />, {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from/i)).toBeInTheDocument()
      })
      await user.click(screen.getByRole('button', {name: /Close/i}))

      expect(onDismissMock).toHaveBeenCalled()
    })

    it('calls onSuccess when apply succeeds', async () => {
      const user = userEvent.setup()
      const onSuccessMock = vi.fn()

      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId/update_requests/:updateRequestId/apply',
          () => {
            return HttpResponse.json({success: true})
          },
        ),
      )

      render(<RegistrationUpdateWizard {...defaultProps} onSuccess={onSuccessMock} />, {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(screen.getByText(/Review Updates from Test Registration/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', {name: /Accept All/i}))

      // Should call onSuccess after successful apply
      await waitFor(() => {
        expect(onSuccessMock).toHaveBeenCalled()
      })
    })
  })
})

function createManualPromise<T = any>() {
  let _resolve: (value: T) => void
  let _reject: (reason?: any) => void

  const promise = new Promise<T>((resolve, reject) => {
    _resolve = resolve
    _reject = reject
  })

  return {
    promise,
    resolve: _resolve!,
    reject: _reject!,
  }
}
