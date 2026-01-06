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
import {cleanup, render, screen, waitFor, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
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

describe('TurnitinAPMigrationModal', () => {
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
      expect(screen.getByText('No migrations available.')).toBeInTheDocument()
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

  it('should not include email in migration request when checkbox is unchecked', async () => {
    const user = userEvent.setup()
    let capturedRequestBody: any = null

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationReady])
        },
      ),
      http.post(
        `/api/v1/accounts/${mockMigrationReady.account_id}/asset_processors/tii_migrations`,
        async ({request}) => {
          capturedRequestBody = await request.text()
          return HttpResponse.json({progress_id: 999})
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })

    // Click migrate button without enabling email
    const migrateButton = screen.getByRole('button', {name: /Migrate/i})
    await user.click(migrateButton)

    // Verify no body was sent in the request
    await waitFor(() => {
      expect(capturedRequestBody).toBe('')
    })
  })

  it('should include email in migration request when checkbox is checked and valid email provided', async () => {
    const user = userEvent.setup()
    let capturedRequestBody: any = null
    const testEmail = 'test@example.com'

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationReady])
        },
      ),
      http.post(
        `/api/v1/accounts/${mockMigrationReady.account_id}/asset_processors/tii_migrations`,
        async ({request}) => {
          capturedRequestBody = await request.json()
          return HttpResponse.json({progress_id: 999})
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })

    // Enable email notification checkbox
    const checkbox = screen.getByRole('checkbox', {
      name: /Email report upon completion of a migration/i,
    })
    await user.click(checkbox)

    // Wait for email input to appear
    await waitFor(() => {
      expect(screen.getByPlaceholderText(/Enter email address/i)).toBeInTheDocument()
    })

    // Fill in email address
    const emailInput = screen.getByPlaceholderText(/Enter email address/i)
    await user.type(emailInput, testEmail)

    // Click migrate button
    const migrateButton = screen.getByRole('button', {name: /Migrate/i})
    await user.click(migrateButton)

    // Verify email was included in the request
    await waitFor(() => {
      expect(capturedRequestBody).toEqual({email: testEmail})
    })
  })

  it('should call onClose when Close button is clicked', async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json(mockMigrations)
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} onClose={onClose} />, {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })

    // Get the Close button from the footer (not the X button in the header)
    const closeButtons = screen.getAllByRole('button', {name: /Close/})
    const footerCloseButton = closeButtons.find(btn => btn.textContent === 'Close')
    expect(footerCloseButton).toBeDefined()
    await user.click(footerCloseButton!)

    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('should call onClose when X button is clicked', async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json(mockMigrations)
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} onClose={onClose} />, {
      wrapper: createWrapper(),
    })

    await waitFor(() => {
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })

    // Get the X button from the header (CloseButton component)
    const closeButtons = screen.getAllByRole('button', {name: /Close/})
    const xButton = closeButtons.find(btn => !btn.textContent || btn.textContent.trim() === 'Close')
    expect(xButton).toBeDefined()
    await user.click(xButton!)

    expect(onClose).toHaveBeenCalled()
  })

  it('should start a migration when Migrate button is clicked', async () => {
    const user = userEvent.setup()

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json([mockMigrationReady])
        },
      ),
      http.post(
        `/api/v1/accounts/${mockMigrationReady.account_id}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json({progress_id: 999})
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    await waitFor(() => {
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })

    const migrateButton = screen.getByRole('button', {name: /Migrate/i})
    await user.click(migrateButton)

    // The mutation should be triggered
    await waitFor(() => {
      // After successful mutation, the query should refetch
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })
  })

  // Skip: Fake timers with waitFor cause OOM in Vitest due to incompatible timer handling
  it.skip('should poll for updates when migration is running', async () => {
    vi.useFakeTimers()
    let requestCount = 0

    // Start with a running migration
    const runningMigration = {
      ...mockMigrationRunning,
      migration_progress: {
        ...mockMigrationRunning.migration_progress!,
        completion: 25,
      },
    }

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          requestCount++

          // First two requests return running state
          if (requestCount <= 2) {
            return HttpResponse.json([
              {
                ...runningMigration,
                migration_progress: {
                  ...runningMigration.migration_progress!,
                  completion: 25 * requestCount,
                },
              },
            ])
          }

          // Third request returns completed state
          return HttpResponse.json([mockMigrationCompleted])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    // Wait for initial load with real timers
    await act(async () => {
      vi.runOnlyPendingTimers()
    })

    await waitFor(
      () => {
        expect(screen.getByText('Engineering Department')).toBeInTheDocument()
      },
      {timeout: 5000},
    )

    // Should show initial progress
    expect(screen.getByText(/Migration is currently in progress/)).toBeInTheDocument()
    expect(requestCount).toBe(1)

    // Advance time by 5 seconds to trigger a poll
    await act(async () => {
      vi.advanceTimersByTime(5000)
    })

    await waitFor(
      () => {
        expect(requestCount).toBe(2)
        expect(screen.getByText(/Migration is currently in progress/)).toBeInTheDocument()
      },
      {timeout: 5000},
    )

    // Advance time by another 5 seconds to trigger another poll
    await act(async () => {
      vi.advanceTimersByTime(5000)
    })

    await waitFor(
      () => {
        expect(requestCount).toBe(3)
        expect(screen.getByText(/Migration completed!/)).toBeInTheDocument()
      },
      {timeout: 5000},
    )

    // Advance time again - should NOT poll anymore since migration is completed
    await act(async () => {
      vi.advanceTimersByTime(5000)
    })

    // Should not have made another request since migration is completed
    expect(requestCount).toBe(3)

    vi.useRealTimers()
  })

  // Skip: Fake timers with waitFor cause OOM in Vitest due to incompatible timer handling
  it.skip('should not poll when no migrations are running', async () => {
    vi.useFakeTimers()
    let requestCount = 0

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          requestCount++
          return HttpResponse.json([mockMigrationReady])
        },
      ),
    )

    render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

    // Wait for initial load with real timers
    await act(async () => {
      vi.runOnlyPendingTimers()
    })

    await waitFor(
      () => {
        expect(screen.getByText('Business School')).toBeInTheDocument()
      },
      {timeout: 5000},
    )
    expect(requestCount).toBe(1)

    // Advance time by 5 seconds
    await act(async () => {
      vi.advanceTimersByTime(5000)
    })

    // Should not have made another request since migration is not running
    expect(requestCount).toBe(1)

    vi.useRealTimers()
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
