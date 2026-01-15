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

describe('TurnitinAPMigrationModal Status', () => {
  const defaultProps = {
    open: true,
    onClose: vi.fn(),
    rootAccountId: '123',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should show Migrate button for non migrated migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationReady])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      const migrateButton = screen.getByRole('button', {name: /Migrate/i})
      expect(migrateButton).toBeInTheDocument()
      expect(migrateButton).toBeEnabled()
    })
  })

  it('should show disabled Migrating button for running migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationRunning])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      const migratingButton = screen.getByRole('button', {name: /Migrating.../i})
      expect(migratingButton).toBeInTheDocument()
      expect(migratingButton).toBeDisabled()
    })
  })

  it('should not show migration button for completed migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationCompleted])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.queryByRole('button', {name: /Migrate/i})).not.toBeInTheDocument()
      expect(screen.queryByRole('button', {name: /Migrating/i})).not.toBeInTheDocument()
    })
  })

  it('should not show migration button for failed migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationFailed])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.queryByRole('button', {name: /Migrate/i})).not.toBeInTheDocument()
    })
  })

  it('should display progress for running migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationRunning])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText(/Migration is currently in progress/)).toBeInTheDocument()
    })
  })

  it('should display completion message for completed migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationCompleted])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText(/Migration completed!/)).toBeInTheDocument()
    })
  })

  it('should display failed message for failed migrations', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationFailed])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText(/Migration failed/)).toBeInTheDocument()
    })
  })

  it('should show download report link for completed migration when report URL is available', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationCompleted])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText(/Migration completed!/)).toBeInTheDocument()
    })

    const downloadLink = screen.getByRole('link', {name: /Download Report/i})
    expect(downloadLink).toBeInTheDocument()
    expect(downloadLink).toHaveAttribute('href', 'https://example.com/migration_report/535')
    expect(downloadLink).toHaveAttribute('target', '_blank')
    expect(downloadLink).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('should show download report link for failed migration when report URL is available', async () => {
    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationFailed])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText(/Migration failed/)).toBeInTheDocument()
    })

    const downloadLink = screen.getByRole('link', {name: /Download Report/i})
    expect(downloadLink).toBeInTheDocument()
    expect(downloadLink).toHaveAttribute('href', 'https://example.com/migration_report/536')
    expect(downloadLink).toHaveAttribute('target', '_blank')
    expect(downloadLink).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('should not show download report link when report URL is not available', async () => {
    const migrationWithoutReport: TiiApMigration = {
      account_id: '5',
      account_name: 'Account Without Report',
      migration_progress: {
        id: '537',
        tag: 'ap_migration',
        workflow_state: 'completed',
        completion: 100,
        results: {},
      },
    }

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([migrationWithoutReport])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText(/Migration completed!/)).toBeInTheDocument()
    })

    const downloadLink = screen.queryByRole('link', {name: /Download Report/i})
    expect(downloadLink).not.toBeInTheDocument()
  })
})
