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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {TurnitinAPMigrationModal} from '../TurnitinAPMigrationModal'
import type {TiiApMigration} from '../TurnitinApMigrationModalState'

// Mock email validation
vi.mock('@canvas/add-people/react/helpers', () => ({
  validateEmailForNewUser: vi.fn(({email}: {email: string}) => {
    if (!email || email.trim() === '') {
      return 'Email is required'
    }
    if (!email.includes('@')) {
      return 'Please enter a valid email address'
    }
    return null
  }),
}))

// Mock flash alerts
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn()),
}))

// Mock data fixtures
const mockMigrationReady: TiiApMigration = {
  account_id: '1',
  account_name: 'Business School',
}

const mockMigrationRunning: TiiApMigration = {
  account_id: '2',
  account_name: 'Engineering Department',
  migration_progress: {
    id: '123',
    tag: 'ap_migration',
    workflow_state: 'running',
    completion: 25,
  },
}

const mockMigrationCompleted: TiiApMigration = {
  account_id: '3',
  account_name: 'Sub Account 3',
  migration_progress: {
    id: '535',
    tag: 'ap_migration',
    workflow_state: 'completed',
    completion: 100,
    results: {
      migration_report_url: 'https://example.com/migration_report/535',
    },
  },
}

const mockMigrationFailed: TiiApMigration = {
  account_id: '4',
  account_name: 'Failed Migration Account',
  migration_progress: {
    id: '536',
    tag: 'ap_migration',
    workflow_state: 'failed',
    completion: 50,
    results: {
      migration_report_url: 'https://example.com/migration_report/536',
    },
  },
}

const mockMigrations: TiiApMigration[] = [
  mockMigrationReady,
  mockMigrationRunning,
  mockMigrationCompleted,
  mockMigrationFailed,
]

// Setup MSW server
const server = setupServer()

beforeAll(() => server.listen({onUnhandledRequest: 'warn'}))
afterEach(() => {
  cleanup()
  server.resetHandlers()
})
afterAll(() => server.close())

// Helper to create a wrapper with QueryClient
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('TurnitinAPMigrationModal Render', () => {
  const defaultProps = {
    open: true,
    onClose: vi.fn(),
    rootAccountId: '123',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should not render when open is false', () => {
    const {container} = render(<TurnitinAPMigrationModal {...defaultProps} />, {
      wrapper: createWrapper(),
    })

    expect(container).toBeEmptyDOMElement()
  })

  it('should show loading state while fetching data', () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json(mockMigrations, {status: 200})
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    expect(screen.getByText('Loading migration data...')).toBeInTheDocument()
  })

  it('should show error state when API fails', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json({error: 'Server error'}, {status: 500})
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(
        screen.getByText('Failed to load migration data. Please try again.'),
      ).toBeInTheDocument()
    })
  })

  it('should show message when no migrations available', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText('There is nothing to migrate.')).toBeInTheDocument()
    })
  })

  it('should render migrations list successfully', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json(mockMigrations)
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText('Business School')).toBeInTheDocument()
      expect(screen.getByText('Engineering Department')).toBeInTheDocument()
      expect(screen.getByText('Sub Account 3')).toBeInTheDocument()
      expect(screen.getByText('Failed Migration Account')).toBeInTheDocument()
    })

    // Verify account links open in new tab with correct href
    const businessSchoolLink = screen.getByRole('link', {name: 'Business School'})
    expect(businessSchoolLink).toHaveAttribute('href', `/accounts/${mockMigrationReady.account_id}`)
    expect(businessSchoolLink).toHaveAttribute('target', '_blank')
  })

  it('should display info alert about migration', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json(mockMigrations)
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(
        screen.getByText(
          /We are replacing LTI 2.0 \(CPF\) with LTI 1.3 \(Asset\/Document Processor\)/,
        ),
      ).toBeInTheDocument()
    })
  })

  it('should display SpeedGrader visibility warning in info alert', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json(mockMigrations)
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(
        screen.getByText(
          /Once you click the button to start the migration, reports will not be visible in SpeedGrader until they have been migrated/,
        ),
      ).toBeInTheDocument()
    })
  })
})
