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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import CourseGradesWidget from '../CourseGradesWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {
  WidgetDashboardProvider,
  type SharedCourseData,
} from '../../../../hooks/useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'

const mockWidget: Widget = {
  id: 'test-course-grades-widget',
  type: 'course_grades',
  position: {col: 1, row: 1, relative: 1},
  title: 'Course Grades',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const mockSharedCourseData: SharedCourseData[] = [
  {
    courseId: '1',
    courseCode: 'CS101',
    courseName: 'Course 1',
    currentGrade: 95,
    gradingScheme: [
      ['A', 0.94],
      ['A-', 0.9],
      ['B+', 0.87],
      ['B', 0.84],
      ['B-', 0.8],
      ['C+', 0.77],
      ['C', 0.74],
      ['C-', 0.7],
      ['D+', 0.67],
      ['D', 0.64],
      ['D-', 0.61],
      ['F', 0],
    ] as Array<[string, number]>,
    lastUpdated: '2025-01-01T00:00:00Z',
  },
  {
    courseId: '2',
    courseCode: 'MATH201',
    courseName: 'Course 2',
    currentGrade: 88,
    gradingScheme: 'percentage',
    lastUpdated: '2025-01-02T00:00:00Z',
  },
]

const setup = (
  props: Partial<BaseWidgetProps> = {},
  sharedCourseData: SharedCourseData[] = mockSharedCourseData,
) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })
  const defaultProps = buildDefaultProps(props)
  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider sharedCourseData={sharedCourseData}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>
            <CourseGradesWidget {...defaultProps} />
          </WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )
}

describe('CourseGradesWidget', () => {
  beforeEach(() => {
    clearWidgetDashboardCache()
  })

  it('renders basic widget', async () => {
    setup({}, [])

    expect(screen.getByText('Course Grades')).toBeInTheDocument()
    expect(screen.queryByText('Loading course grades...')).not.toBeInTheDocument()
  })

  it('displays courses with shared data', async () => {
    setup()

    await waitFor(() => {
      expect(screen.getByText('Course 1')).toBeInTheDocument()
      expect(screen.getByText('Course 2')).toBeInTheDocument()
    })
  })

  it('renders courses with null grades', async () => {
    const courseDataWithNullGrade: SharedCourseData[] = [
      {
        courseId: '1',
        courseCode: 'CS101',
        courseName: 'Course Without Grade',
        currentGrade: null,
        gradingScheme: 'percentage',
        lastUpdated: '2025-01-01T00:00:00Z',
      },
    ]

    setup({}, courseDataWithNullGrade)

    await waitFor(() => {
      expect(screen.getByText('Course Without Grade')).toBeInTheDocument()
    })
  })

  it('displays grades when available', async () => {
    const courseDataWithGrade: SharedCourseData[] = [
      {
        courseId: '1',
        courseCode: 'CS101',
        courseName: 'Course With Grade',
        currentGrade: 92.5,
        gradingScheme: 'percentage',
        lastUpdated: '2025-01-01T00:00:00Z',
      },
    ]

    setup({}, courseDataWithGrade)

    await waitFor(() => {
      expect(screen.getByText('Course With Grade')).toBeInTheDocument()
      expect(screen.getByText('92%')).toBeInTheDocument()
    })
  })

  it('handles mix of courses with and without grades', async () => {
    const mixedCourseData: SharedCourseData[] = [
      {
        courseId: '1',
        courseCode: 'CS101',
        courseName: 'Course With Grade',
        currentGrade: 85,
        gradingScheme: 'percentage',
        lastUpdated: '2025-01-01T00:00:00Z',
      },
      {
        courseId: '2',
        courseCode: 'MATH201',
        courseName: 'Course Without Grade',
        currentGrade: null,
        gradingScheme: 'percentage',
        lastUpdated: '2025-01-02T00:00:00Z',
      },
    ]

    setup({}, mixedCourseData)

    await waitFor(() => {
      expect(screen.getByText('Course With Grade')).toBeInTheDocument()
      expect(screen.getByText('Course Without Grade')).toBeInTheDocument()
      expect(screen.getByText('85%')).toBeInTheDocument()
    })
  })

  it('displays "Go to course" link for each course', async () => {
    setup()

    await waitFor(() => {
      expect(screen.getByText('Course 1')).toBeInTheDocument()
      expect(screen.getByText('Course 2')).toBeInTheDocument()
    })

    expect(screen.getByTestId('course-1-link')).toBeInTheDocument()
    expect(screen.getByTestId('course-1-link')).toHaveAttribute('href', '/courses/1')
    expect(screen.getByTestId('course-2-link')).toBeInTheDocument()
    expect(screen.getByTestId('course-2-link')).toHaveAttribute('href', '/courses/2')
  })
})
