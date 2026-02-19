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

describe('TurnitinAPMigrationModal Actions', () => {
  const defaultProps = {
    open: true,
    onClose: vi.fn(),
    rootAccountId: '123',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should not include email in migration request when checkbox is unchecked', async () => {
    const user = userEvent.setup()
    let capturedRequestBody: any = null

    server.use(
      http.get(
        `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
        () => {
          return HttpResponse.json({accounts: [mockMigrationReady], coordinator_progress: null})
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

    // Click migrate button without enabling email (not "Migrate All")
    const migrateButton = screen.getByRole('button', {name: /^Migrate$/i})
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
          return HttpResponse.json({accounts: [mockMigrationReady], coordinator_progress: null})
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

    // Click migrate button (not "Migrate All")
    const migrateButton = screen.getByRole('button', {name: /^Migrate$/i})
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
          return HttpResponse.json({accounts: mockMigrations, coordinator_progress: null})
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
          return HttpResponse.json({accounts: mockMigrations, coordinator_progress: null})
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
          return HttpResponse.json({accounts: [mockMigrationReady], coordinator_progress: null})
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

    const migrateButton = screen.getByRole('button', {name: /^Migrate$/i})
    await user.click(migrateButton)

    // The mutation should be triggered
    await waitFor(() => {
      // After successful mutation, the query should refetch
      expect(screen.getByText('Business School')).toBeInTheDocument()
    })
  })

  describe('Migrate All functionality', () => {
    it('should show "Migrate All" button when eligible migrations exist', async () => {
      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationReady, mockMigrationFailed],
              coordinator_progress: null,
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrate All/i})).toBeInTheDocument()
      })
    })

    it('should hide "Migrate All" button when all migrations are completed or running', async () => {
      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationRunning, mockMigrationCompleted],
              coordinator_progress: null,
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Engineering Department')).toBeInTheDocument()
      })

      expect(screen.queryByRole('button', {name: /Migrate All/i})).not.toBeInTheDocument()
    })

    it('should hide "Migrate All" button when there is only one eligible migration', async () => {
      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({accounts: [mockMigrationReady], coordinator_progress: null})
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Business School')).toBeInTheDocument()
      })

      expect(screen.queryByRole('button', {name: /Migrate All/i})).not.toBeInTheDocument()
    })

    it('should call migrate_all endpoint when "Migrate All" is clicked', async () => {
      const user = userEvent.setup()
      let migrateAllCalled = false

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationReady, mockMigrationFailed],
              coordinator_progress: null,
            })
          },
        ),
        http.post(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations/migrate_all`,
          () => {
            migrateAllCalled = true
            return HttpResponse.json({
              message: 'Started migration for 2 accounts',
              progress_ids: [1001, 1002],
              account_ids: ['1', '4'],
              bulk_migration_id: 'test-uuid',
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrate All/i})).toBeInTheDocument()
      })

      const migrateAllButton = screen.getByRole('button', {name: /Migrate All/i})
      await user.click(migrateAllButton)

      await waitFor(() => {
        expect(migrateAllCalled).toBe(true)
      })
    })

    it('should include email in migrate_all request when checkbox is checked', async () => {
      const user = userEvent.setup()
      let capturedRequestBody: any = null
      const testEmail = 'test@example.com'

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationReady, mockMigrationFailed],
              coordinator_progress: null,
            })
          },
        ),
        http.post(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations/migrate_all`,
          async ({request}) => {
            capturedRequestBody = await request.json()
            return HttpResponse.json({
              message: 'Started migration for 2 accounts',
              progress_ids: [1001, 1002],
              account_ids: ['1', '4'],
              bulk_migration_id: 'test-uuid',
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrate All/i})).toBeInTheDocument()
      })

      // Enable email notification checkbox
      const checkbox = screen.getByRole('checkbox', {
        name: /Email report upon completion of a migration/i,
      })
      await user.click(checkbox)

      // Fill in email address
      const emailInput = screen.getByPlaceholderText(/Enter email address/i)
      await user.type(emailInput, testEmail)

      // Click Migrate All button
      const migrateAllButton = screen.getByRole('button', {name: /Migrate All/i})
      await user.click(migrateAllButton)

      await waitFor(() => {
        expect(capturedRequestBody).toEqual({email: testEmail})
      })
    })

    it('should not include email in migrate_all request when checkbox is unchecked', async () => {
      const user = userEvent.setup()
      let capturedRequestBody: any = null

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationReady, mockMigrationFailed],
              coordinator_progress: null,
            })
          },
        ),
        http.post(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations/migrate_all`,
          async ({request}) => {
            capturedRequestBody = await request.text()
            return HttpResponse.json({
              message: 'Started migration for 2 accounts',
              progress_ids: [1001, 1002],
              account_ids: ['1', '4'],
              bulk_migration_id: 'test-uuid',
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrate All/i})).toBeInTheDocument()
      })

      // Click Migrate All button without enabling email
      const migrateAllButton = screen.getByRole('button', {name: /Migrate All/i})
      await user.click(migrateAllButton)

      await waitFor(() => {
        expect(capturedRequestBody).toBe('')
      })
    })

    it('should disable "Migrate All" button when email validation fails', async () => {
      const user = userEvent.setup()
      let migrateAllCalled = false

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationReady, mockMigrationFailed],
              coordinator_progress: null,
            })
          },
        ),
        http.post(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations/migrate_all`,
          () => {
            migrateAllCalled = true
            return HttpResponse.json({
              message: 'Started migration for 2 accounts',
              progress_ids: [1001, 1002],
              account_ids: ['1', '4'],
              bulk_migration_id: 'test-uuid',
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrate All/i})).toBeInTheDocument()
      })

      // Enable email notification checkbox
      const checkbox = screen.getByRole('checkbox', {
        name: /Email report upon completion of a migration/i,
      })
      await user.click(checkbox)

      // Enter invalid email (no @)
      const emailInput = screen.getByPlaceholderText(/Enter email address/i)
      await user.type(emailInput, 'invalidemail')

      // Try to click Migrate All button - should not trigger mutation due to disabled state
      const migrateAllButton = screen.getByRole('button', {name: /Migrate All/i})
      await user.click(migrateAllButton)

      // Wait a bit to ensure the mutation doesn't fire
      await new Promise(resolve => setTimeout(resolve, 100))

      // Verify the migrate_all endpoint was not called
      expect(migrateAllCalled).toBe(false)
    })

    it('should show "Migrating All..." text during pending state', async () => {
      const user = userEvent.setup()

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockMigrationReady, mockMigrationFailed],
              coordinator_progress: null,
            })
          },
        ),
        http.post(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations/migrate_all`,
          async () => {
            // Delay response to simulate loading state
            await new Promise(resolve => setTimeout(resolve, 100))
            return HttpResponse.json({
              message: 'Started migration for 2 accounts',
              progress_ids: [1001, 1002],
              account_ids: ['1', '4'],
              bulk_migration_id: 'test-uuid',
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrate All/i})).toBeInTheDocument()
      })

      const migrateAllButton = screen.getByRole('button', {name: /Migrate All/i})
      await user.click(migrateAllButton)

      // Should show "Migrating All..." during pending state
      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Migrating All.../i})).toBeInTheDocument()
      })
    })

    it('should show consolidated report link when coordinator progress is completed', async () => {
      const consolidatedReportUrl = 'https://example.com/consolidated_report.csv'
      const mockCompletedAccount1 = {
        ...mockMigrationCompleted,
        account_id: '20',
        account_name: 'Completed Account 1',
      }
      const mockCompletedAccount2 = {
        ...mockMigrationCompleted,
        account_id: '21',
        account_name: 'Completed Account 2',
      }

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockCompletedAccount1, mockCompletedAccount2],
              coordinator_progress: {
                id: 'coordinator-123',
                workflow_state: 'completed',
                consolidated_report_url: consolidatedReportUrl,
              },
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Download Consolidated Report')).toBeInTheDocument()
      })

      const consolidatedLink = screen.getByText('Download Consolidated Report')
      expect(consolidatedLink).toHaveAttribute('href', consolidatedReportUrl)
      expect(consolidatedLink).toHaveAttribute('target', '_blank')
    })

    it('should not show Migrate All button when consolidated report is available', async () => {
      const mockCompletedAccount3 = {
        ...mockMigrationCompleted,
        account_id: '22',
        account_name: 'Completed Account 3',
      }
      const mockCompletedAccount4 = {
        ...mockMigrationCompleted,
        account_id: '23',
        account_name: 'Completed Account 4',
      }

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockCompletedAccount3, mockCompletedAccount4],
              coordinator_progress: {
                id: 'coordinator-123',
                workflow_state: 'completed',
                consolidated_report_url: 'https://example.com/report.csv',
              },
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Download Consolidated Report')).toBeInTheDocument()
      })

      expect(screen.queryByRole('button', {name: /Migrate All/i})).not.toBeInTheDocument()
    })

    it('should show disabled "Migrate All" button when coordinator is running', async () => {
      const mockRunningAccount1 = {
        ...mockMigrationRunning,
        account_id: '10',
        account_name: 'Running Account 1',
      }
      const mockRunningAccount2 = {
        ...mockMigrationRunning,
        account_id: '11',
        account_name: 'Running Account 2',
      }

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockRunningAccount1, mockRunningAccount2],
              coordinator_progress: {
                id: 'coordinator-123',
                workflow_state: 'running',
                consolidated_report_url: null,
              },
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Running Account 1')).toBeInTheDocument()
      })

      const migrateAllButton = screen.getByRole('button', {name: /Migrating All.../i})
      expect(migrateAllButton).toBeInTheDocument()
      expect(migrateAllButton).toHaveAttribute('type', 'button')
    })

    it('should show disabled "Migrate All" button when coordinator is queued', async () => {
      const mockQueuedAccount1 = {
        ...mockMigrationReady,
        account_id: '12',
        account_name: 'Queued Account 1',
      }
      const mockQueuedAccount2 = {
        ...mockMigrationReady,
        account_id: '13',
        account_name: 'Queued Account 2',
      }

      server.use(
        http.get(
          `/api/v1/accounts/${defaultProps.rootAccountId}/asset_processors/tii_migrations`,
          () => {
            return HttpResponse.json({
              accounts: [mockQueuedAccount1, mockQueuedAccount2],
              coordinator_progress: {
                id: 'coordinator-123',
                workflow_state: 'queued',
                consolidated_report_url: null,
              },
            })
          },
        ),
      )

      render(<TurnitinAPMigrationModal {...defaultProps} />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText('Queued Account 1')).toBeInTheDocument()
      })

      const migrateAllButton = screen.getByRole('button', {name: /Migrating All.../i})
      expect(migrateAllButton).toBeInTheDocument()
      expect(migrateAllButton).toHaveAttribute('type', 'button')
    })
  })
})
