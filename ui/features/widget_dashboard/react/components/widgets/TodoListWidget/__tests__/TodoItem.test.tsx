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

const server = setupServer(...plannerOverrideHandlers)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

const renderWithProvider = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false},
      mutations: {retry: false},
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider
        sharedCourseData={mockSharedCourseData}
        preferences={mockPreferences}
      >
        {ui}
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )
}

describe('TodoItem', () => {
  it('renders item title as link', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    const link = screen.getByTestId(`todo-link-${item.plannable_id}`)
    expect(link).toHaveTextContent('Lab Report: Cell Structure')
    expect(link).toHaveAttribute('href', '/courses/1/assignments/1')
  })

  it('renders enabled checkbox button', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
    expect(button).toBeInTheDocument()
    expect(button).toBeEnabled()
  })

  it('displays course code when available', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    expect(screen.getByText('BIO101')).toBeInTheDocument()
  })

  it('displays points possible when available', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    expect(screen.getByText(/100 pts/)).toBeInTheDocument()
  })

  it('does not display points for items without points_possible', () => {
    const item = mockPlannerItems[3]
    renderWithProvider(<TodoItem item={item} />)

    expect(screen.queryByText('pts')).not.toBeInTheDocument()
  })

  it('displays item type label', () => {
    const assignmentItem = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={assignmentItem} />)

    expect(screen.getByText('Assignment')).toBeInTheDocument()
  })

  it('displays course code as pill when course_id is present', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    expect(screen.getByText('BIO101')).toBeInTheDocument()
  })

  it('displays description when available', () => {
    const itemWithDetails = {
      ...mockPlannerItems[0],
      plannable: {
        ...mockPlannerItems[0].plannable,
        details: 'This is a test description',
      },
    }
    renderWithProvider(<TodoItem item={itemWithDetails} />)

    expect(screen.getByText('This is a test description')).toBeInTheDocument()
  })

  it('does not display description when not available', () => {
    const itemWithoutDetails = {
      ...mockPlannerItems[0],
      plannable: {
        ...mockPlannerItems[0].plannable,
        details: undefined,
      },
    }
    renderWithProvider(<TodoItem item={itemWithoutDetails} />)

    expect(screen.queryByText(/description/i)).not.toBeInTheDocument()
  })

  it('displays "Go to course" link when course_id is present', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    const courseLink = screen.getByTestId(`todo-item-course-link-${item.plannable_id}`)
    expect(courseLink).toBeInTheDocument()
    expect(courseLink).toHaveAttribute('href', '/courses/1')
    expect(courseLink).toHaveTextContent('Go to course')
  })

  it('does not display "Go to course" link when course_id is not present', () => {
    const itemWithoutCourse = {
      ...mockPlannerItems[0],
      course_id: undefined,
    }
    renderWithProvider(<TodoItem item={itemWithoutCourse} />)

    expect(screen.queryByText('Go to course')).not.toBeInTheDocument()
  })

  describe('checkbox functionality', () => {
    it('shows unchecked icon when item is not marked complete', () => {
      const item = mockPlannerItems[0]
      renderWithProvider(<TodoItem item={item} />)

      const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
      expect(button).toBeInTheDocument()
      expect(button.querySelector('svg')).toBeInTheDocument()
    })

    it('shows checked icon when item is marked complete', () => {
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
      renderWithProvider(<TodoItem item={completedItem} />)

      const button = screen.getByTestId(`todo-checkbox-${completedItem.plannable_id}`)
      expect(button).toBeInTheDocument()
    })

    it('applies secondary text color to completed items', () => {
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
      renderWithProvider(<TodoItem item={completedItem} />)

      const link = screen.getByTestId(`todo-link-${completedItem.plannable_id}`)
      const titleText = link.querySelector('span')
      expect(titleText).toHaveAttribute('color', 'secondary')
    })

    it('marks item as complete when checkbox is clicked', async () => {
      const user = userEvent.setup()
      const item = mockPlannerItems[0]
      renderWithProvider(<TodoItem item={item} />)

      const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
      await user.click(button)

      await waitFor(() => {
        expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
      })
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
      renderWithProvider(<TodoItem item={completedItem} />)

      const button = screen.getByTestId(`todo-checkbox-${completedItem.plannable_id}`)
      await user.click(button)

      await waitFor(() => {
        expect(
          screen.queryByTestId(`todo-checkbox-loading-${completedItem.plannable_id}`),
        ).toBeNull()
      })
    })

    it('completes API call successfully', async () => {
      const user = userEvent.setup()
      const item = mockPlannerItems[0]
      renderWithProvider(<TodoItem item={item} />)

      const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
      await user.click(button)

      await waitFor(() => {
        expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
      })
    })

    it('handles error when creating override fails', async () => {
      server.use(errorCreateOverrideHandler)

      const user = userEvent.setup()
      const item = mockPlannerItems[0]
      renderWithProvider(<TodoItem item={item} />)

      const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
      await user.click(button)

      await waitFor(() => {
        expect(screen.queryByTestId(`todo-checkbox-loading-${item.plannable_id}`)).toBeNull()
      })
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
      renderWithProvider(<TodoItem item={completedItem} />)

      const button = screen.getByTestId(`todo-checkbox-${completedItem.plannable_id}`)
      await user.click(button)

      await waitFor(() => {
        expect(
          screen.queryByTestId(`todo-checkbox-loading-${completedItem.plannable_id}`),
        ).toBeNull()
      })
    })

    it('updates screen reader label based on completion state', () => {
      const item = mockPlannerItems[0]
      renderWithProvider(<TodoItem item={item} />)

      expect(screen.getByText('Mark Lab Report: Cell Structure as complete')).toBeInTheDocument()
    })

    it('updates screen reader label for completed items', () => {
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
      renderWithProvider(<TodoItem item={completedItem} />)

      expect(screen.getByText('Mark Lab Report: Cell Structure as incomplete')).toBeInTheDocument()
    })
  })
})
