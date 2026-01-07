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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import TodoListWidget from '../TodoListWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {
  plannerItemsHandlers,
  emptyPlannerItemsHandler,
  errorPlannerItemsHandler,
  plannerNoteHandlers,
} from './mocks/handlers'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'

const mockWidget: Widget = {
  id: 'todo-list-widget',
  type: 'todo_list',
  position: {col: 1, row: 1, relative: 1},
  title: 'To-do list',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const server = setupServer(...plannerItemsHandlers, ...plannerNoteHandlers)

const mockSharedCourseData = [
  {
    courseId: '1',
    courseCode: 'TC1',
    courseName: 'Test Course 1',
    currentGrade: null,
    gradingScheme: 'percentage' as const,
    lastUpdated: new Date().toISOString(),
  },
  {
    courseId: '2',
    courseCode: 'TC2',
    courseName: 'Test Course 2',
    currentGrade: null,
    gradingScheme: 'percentage' as const,
    lastUpdated: new Date().toISOString(),
  },
]

beforeAll(() => {
  server.listen()
})
beforeEach(() => {
  fakeENV.setup({
    LOCALE: 'en',
    TIMEZONE: 'America/Denver',
  })
  clearWidgetDashboardCache()
})
afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
})
afterAll(() => server.close())

const renderWithClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider sharedCourseData={mockSharedCourseData}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>{ui}</WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )
}

describe('TodoListWidget - Pagination', () => {
  it('shows pagination when multiple pages exist', async () => {
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const paginationContainer = await waitFor(
      () => {
        const container = screen.queryByTestId('pagination-container')
        if (!container) throw new Error('Pagination not found')
        return container
      },
      {timeout: 5000},
    )

    expect(paginationContainer).toBeInTheDocument()
  })

  it('allows navigation to next page', async () => {
    const user = userEvent.setup()
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const paginationContainer = await waitFor(
      () => {
        const container = screen.queryByTestId('pagination-container')
        if (!container) throw new Error('Pagination not found')
        return container
      },
      {timeout: 5000},
    )

    const page2Button = screen.getByRole('button', {name: '2'})
    expect(page2Button).toBeInTheDocument()

    await user.click(page2Button)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })
  })
})

describe('TodoListWidget - Empty State', () => {
  it('shows appropriate message when no items', async () => {
    server.use(emptyPlannerItemsHandler)
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.getByTestId('no-todos-message')).toBeInTheDocument()
    })

    expect(screen.getByText('No upcoming items')).toBeInTheDocument()
  })

  it('does not show pagination when no items', async () => {
    server.use(emptyPlannerItemsHandler)
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.getByText('No upcoming items')).toBeInTheDocument()
    })

    expect(screen.queryByTestId('pagination-container')).not.toBeInTheDocument()
  })
})

describe('TodoListWidget - Error Handling', () => {
  it('shows error message on API failure', async () => {
    server.use(errorPlannerItemsHandler)
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(
      () => {
        expect(
          screen.getByText('Failed to load to-do items. Please try again.'),
        ).toBeInTheDocument()
      },
      {timeout: 5000},
    )
  })

  it('shows retry button on error', async () => {
    server.use(errorPlannerItemsHandler)
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(
      () => {
        expect(screen.getByRole('button', {name: /retry/i})).toBeInTheDocument()
      },
      {timeout: 5000},
    )
  })

  it('retries fetch when retry button clicked', async () => {
    const user = userEvent.setup()
    server.use(errorPlannerItemsHandler)
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(
      () => {
        expect(
          screen.getByText('Failed to load to-do items. Please try again.'),
        ).toBeInTheDocument()
      },
      {timeout: 5000},
    )

    server.resetHandlers()
    server.use(...plannerItemsHandlers)

    const retryButton = screen.getByRole('button', {name: /retry/i})
    await user.click(retryButton)

    await waitFor(() => {
      expect(screen.getByText('Lab Report: Cell Structure')).toBeInTheDocument()
    })
  })
})
