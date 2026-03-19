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
import TodoItem from '../TodoItem'
import {mockPlannerItems} from './mocks/data'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'
import {setupServer} from 'msw/node'
import {
  plannerItemsHandlers,
  plannerOverrideHandlers,
  errorCreateOverrideHandler,
  errorUpdateOverrideHandler,
} from './mocks/handlers'

const mockSharedCourseData = [
  {
    courseId: '1',
    courseCode: 'BIO101',
    courseName: 'Biology 101',
    currentGrade: 85,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-01-15T00:00:00Z',
  },
]

const mockPreferences = {
  dashboard_view: 'cards',
  hide_dashcard_color_overlays: false,
  custom_colors: {},
}

const server = setupServer(...plannerItemsHandlers, ...plannerOverrideHandlers)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

const setup = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false, gcTime: 0},
      mutations: {retry: false},
    },
  })

  const result = render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider
        sharedCourseData={mockSharedCourseData}
        preferences={mockPreferences}
      >
        {ui}
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )

  return {
    ...result,
    cleanup: () => {
      queryClient.clear()
    },
  }
}

describe('TodoItem mutation tests', () => {
  it('marks item as complete when checkbox is clicked', async () => {
    const user = userEvent.setup()
    const item = mockPlannerItems[0]
    const {cleanup} = setup(<TodoItem item={item} />)

    const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
    await user.click(button)

    await waitFor(() => {
      expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
    })

    cleanup()
  })

  it('marks item as incomplete when checked checkbox is clicked', async () => {
    const user = userEvent.setup()
    const completedItem = {
      ...mockPlannerItems[0],
      planner_override: {
        id: 1,
        plannable_type: 'assignment',
        plannable_id: '1',
        user_id: 1,
        workflow_state: 'active',
        marked_complete: true,
        dismissed: false,
        deleted_at: null,
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z',
      },
    }
    const {cleanup} = setup(<TodoItem item={completedItem} />)

    const button = screen.getByTestId(`todo-checkbox-${completedItem.plannable_id}`)
    await user.click(button)

    await waitFor(() => {
      expect(screen.queryByTestId(`todo-checkbox-loading-${completedItem.plannable_id}`)).toBeNull()
    })

    cleanup()
  })

  it('completes API call successfully', async () => {
    const user = userEvent.setup()
    const item = mockPlannerItems[0]
    const {cleanup} = setup(<TodoItem item={item} />)

    const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
    await user.click(button)

    await waitFor(() => {
      expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
    })

    cleanup()
  })

  it('handles error when creating override fails', async () => {
    server.use(errorCreateOverrideHandler)

    const user = userEvent.setup()
    const item = mockPlannerItems[0]
    const {cleanup} = setup(<TodoItem item={item} />)

    const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
    await user.click(button)

    await waitFor(() => {
      expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
    })

    cleanup()
  })

  it('handles error when updating override fails', async () => {
    server.use(errorUpdateOverrideHandler)

    const user = userEvent.setup()
    const completedItem = {
      ...mockPlannerItems[0],
      planner_override: {
        id: 1,
        plannable_type: 'assignment',
        plannable_id: '1',
        user_id: 1,
        workflow_state: 'active',
        marked_complete: true,
        dismissed: false,
        deleted_at: null,
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z',
      },
    }
    const {cleanup} = setup(<TodoItem item={completedItem} />)

    const button = screen.getByTestId(`todo-checkbox-${completedItem.plannable_id}`)
    await user.click(button)

    await waitFor(() => {
      expect(screen.queryByTestId(`todo-checkbox-loading-${completedItem.plannable_id}`)).toBeNull()
    })

    cleanup()
  })

  it('restores focus to button after toggling complete', async () => {
    const user = userEvent.setup()
    const item = mockPlannerItems[0]
    const {cleanup} = setup(<TodoItem item={item} />)

    const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
    await user.click(button)

    await waitFor(() => {
      expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
    })

    expect(button).toHaveFocus()

    cleanup()
  })
})
