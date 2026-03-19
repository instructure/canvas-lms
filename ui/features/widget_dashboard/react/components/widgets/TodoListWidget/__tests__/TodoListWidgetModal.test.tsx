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

describe('TodoListWidget - Create Todo Modal', () => {
  it('opens modal when "+ New To-do" button is clicked', async () => {
    const user = userEvent.setup()
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const newButton = screen.getByTestId('new-todo-button')
    await user.click(newButton)

    await waitFor(() => {
      expect(screen.getByText('Add To Do')).toBeInTheDocument()
    })
  })

  it('closes modal when cancel button is clicked', async () => {
    const user = userEvent.setup()
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const newButton = screen.getByTestId('new-todo-button')
    await user.click(newButton)

    await waitFor(() => {
      expect(screen.getByText('Add To Do')).toBeInTheDocument()
    })

    const cancelButton = screen.getByTestId('create-todo-cancel-button')
    await user.click(cancelButton)

    await waitFor(() => {
      expect(screen.queryByText('Add To Do')).not.toBeInTheDocument()
    })
  })

  it('renders create todo modal with all fields', async () => {
    const user = userEvent.setup()
    renderWithClient(<TodoListWidget {...buildDefaultProps()} />)

    await waitFor(() => {
      expect(screen.queryByText('Loading to-do items...')).not.toBeInTheDocument()
    })

    const newButton = screen.getByTestId('new-todo-button')
    await user.click(newButton)

    await waitFor(() => {
      expect(screen.getByText('Add To Do')).toBeInTheDocument()
    })

    expect(screen.getByTestId('create-todo-title-input')).toBeInTheDocument()
    expect(screen.getByTestId('create-todo-date-input')).toBeInTheDocument()
    expect(screen.getByTestId('create-todo-course-select')).toBeInTheDocument()
    expect(screen.getByTestId('create-todo-details-input')).toBeInTheDocument()
  })
})
