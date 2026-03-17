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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks/dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import * as React from 'react'
import useInstallStatus from '../useInstallStatus'
import type {LtiRegistration} from '../../models/LtiRegistration'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const mockInstallStatus: LtiRegistration = {
  id: '123',
}

const defaultHandlers = [
  http.get(
    'http://localhost/api/v1/accounts/:account_id/lti_registrations/install_status/:client_id',
    () => {
      return HttpResponse.json(mockInstallStatus)
    },
  ),
]

const server = setupServer(...defaultHandlers)

beforeAll(() => {
  server.listen({onUnhandledRequest: 'warn'})
})
afterEach(() => {
  server.resetHandlers()
})
afterAll(() => server.close())

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

describe('useInstallStatus', () => {
  beforeEach(() => {
    // Mock window.location with full URL
    Object.defineProperty(window, 'location', {
      value: new URL('http://localhost/accounts/1/apps'),
      writable: true,
      configurable: true,
    })
  })

  it('fetches install status successfully using developer key ID', async () => {
    const queryClient = createQueryClient()

    const {result} = renderHook(() => useInstallStatus('12345'), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.data).toEqual(mockInstallStatus)
    expect(result.current.isError).toBe(false)
  })

  it('returns null for 404 (not installed)', async () => {
    server.use(
      http.get(
        'http://localhost/api/v1/accounts/:account_id/lti_registrations/install_status/:client_id',
        () => {
          return new HttpResponse(null, {status: 404})
        },
      ),
    )

    const queryClient = createQueryClient()

    const {result} = renderHook(() => useInstallStatus('99999'), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.data).toBe(null)
    expect(result.current.isError).toBe(false)
  })

  it('handles network errors', async () => {
    server.use(
      http.get(
        'http://localhost/api/v1/accounts/:account_id/lti_registrations/install_status/:client_id',
        () => {
          return new HttpResponse(null, {status: 500})
        },
      ),
    )

    const queryClient = createQueryClient()

    const {result} = renderHook(() => useInstallStatus('error-key'), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    await waitFor(() => expect(result.current.isError).toBe(true))

    expect(result.current.data).toBe(undefined)
  })

  it('disables query when developerKeyId is missing', () => {
    const queryClient = createQueryClient()

    const {result} = renderHook(() => useInstallStatus(undefined), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBe(undefined)
  })

  it('fetches tool status correctly', async () => {
    const status: LtiRegistration = {
      id: '789',
    }

    server.use(
      http.get(
        'http://localhost/api/v1/accounts/:account_id/lti_registrations/install_status/:client_id',
        () => {
          return HttpResponse.json(status)
        },
      ),
    )

    const queryClient = createQueryClient()

    const {result} = renderHook(() => useInstallStatus('inherited-key'), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.data).toEqual(status)
    expect(result.current.data?.id).toBe('789')
  })
})
