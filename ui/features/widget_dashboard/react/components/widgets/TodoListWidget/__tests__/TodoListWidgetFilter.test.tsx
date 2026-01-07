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
import {plannerItemsHandlers, plannerNoteHandlers} from './mocks/handlers'
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

describe('TodoListWidget - Filter Dropdown', () => {
  it('renders filter dropdown', async () => {
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    expect(screen.getByTestId('todo-filter-select')).toBeInTheDocument()
  })

  it('initializes with persisted filter value', async () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    const persistedPreferences = {
      dashboard_view: 'cards',
      hide_dashcard_color_overlays: false,
      custom_colors: {},
      widget_dashboard_config: {
        filters: {
          'todo-list-widget': {
            filter: 'complete_items',
          },
        },
      },
    }

    render(
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardProvider
          sharedCourseData={mockSharedCourseData}
          preferences={persistedPreferences}
        >
          <WidgetDashboardEditProvider>
            <WidgetLayoutProvider>
              <TodoListWidget {...buildDefaultProps()} />
            </WidgetLayoutProvider>
          </WidgetDashboardEditProvider>
        </WidgetDashboardProvider>
      </QueryClientProvider>,
    )

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const filterSelect = screen.getByTestId('todo-filter-select')
    expect(filterSelect).toHaveValue('Complete')
  })

  it('defaults to Incomplete filter', async () => {
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const filterSelect = screen.getByTestId('todo-filter-select')
    expect(filterSelect).toHaveValue('Incomplete')
  })

  it('can change to Complete filter', async () => {
    global.event = undefined // workaround bug in SimpleSelect that accesses the global event
    const user = userEvent.setup()
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const filterSelect = screen.getByTestId('todo-filter-select')
    await user.click(filterSelect)

    const completeOption = await screen.findByText('Complete')
    await user.click(completeOption)

    // Wait for the filter to update and refetch to complete
    await waitFor(
      () => {
        const updatedFilterSelect = screen.getByTestId('todo-filter-select')
        expect(updatedFilterSelect).toHaveValue('Complete')
      },
      {timeout: 3000},
    )
  })

  it('can change to All filter', async () => {
    global.event = undefined // workaround bug in SimpleSelect that accesses the global event
    const user = userEvent.setup()
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const filterSelect = screen.getByTestId('todo-filter-select')
    await user.click(filterSelect)

    const allOption = await screen.findByText('All')
    await user.click(allOption)

    // Wait for the filter to update and refetch to complete
    await waitFor(
      () => {
        const updatedFilterSelect = screen.getByTestId('todo-filter-select')
        expect(updatedFilterSelect).toHaveValue('All')
      },
      {timeout: 3000},
    )
  })

  it('filter is placed in widget body', async () => {
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const filterSelect = screen.getByTestId('todo-filter-select')
    const newButton = screen.getByTestId('new-todo-button')

    expect(filterSelect).toBeInTheDocument()
    expect(newButton).toBeInTheDocument()
  })
})
