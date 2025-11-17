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
import {render, screen} from '@testing-library/react'
import TodoItem from '../TodoItem'
import {mockPlannerItems} from './mocks/data'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'

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

const renderWithProvider = (ui: React.ReactElement) => {
  return render(
    <WidgetDashboardProvider sharedCourseData={mockSharedCourseData} preferences={mockPreferences}>
      {ui}
    </WidgetDashboardProvider>,
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

  it('renders disabled icon button', () => {
    const item = mockPlannerItems[0]
    renderWithProvider(<TodoItem item={item} />)

    const button = screen.getByTestId(`todo-checkbox-${item.plannable_id}`)
    expect(button).toBeInTheDocument()
    expect(button).toBeDisabled()
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
})
