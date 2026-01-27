/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import PeopleFilters from '../PeopleFilters'

vi.mock('@canvas/query/broadcast', () => ({
  useBroadcastQuery: vi.fn(),
}))

const server = setupServer(
  graphql.query('GetUserCoursesWithGradesConnection', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [
              {
                courseName: 'Math 101',
                courseCode: 'MATH101',
                course: {_id: '1', name: 'Math 101'},
                grades: {currentScore: 85.5},
              },
              {
                courseName: 'Science 201',
                courseCode: 'SCI201',
                course: {_id: '2', name: 'Science 201'},
                grades: {currentScore: 92.0},
              },
            ],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
            },
          },
        },
      },
    })
  }),
)

const renderWithQueryClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
}

describe('PeopleFilters', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    window.ENV = {
      current_user_id: '123',
      GRAPHQL_URL: '/api/graphql',
      CSRF_TOKEN: 'mock-csrf-token',
    } as any
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('renders course filter', () => {
    const onCourseChange = vi.fn()
    const onRoleChange = vi.fn()

    renderWithQueryClient(
      <PeopleFilters
        selectedCourse="all"
        selectedRole="all"
        onCourseChange={onCourseChange}
        onRoleChange={onRoleChange}
      />,
    )

    expect(screen.getByTestId('course-filter-select')).toBeInTheDocument()
  })

  it('renders role filter', () => {
    const onCourseChange = vi.fn()
    const onRoleChange = vi.fn()

    renderWithQueryClient(
      <PeopleFilters
        selectedCourse="all"
        selectedRole="all"
        onCourseChange={onCourseChange}
        onRoleChange={onRoleChange}
      />,
    )

    expect(screen.getByTestId('role-filter-select')).toBeInTheDocument()
  })

  it('calls onCourseChange when course filter changes', async () => {
    const user = userEvent.setup()
    const onCourseChange = vi.fn()
    const onRoleChange = vi.fn()

    renderWithQueryClient(
      <PeopleFilters
        selectedCourse="all"
        selectedRole="all"
        onCourseChange={onCourseChange}
        onRoleChange={onRoleChange}
      />,
    )

    const courseFilter = screen.getByTestId('course-filter-select')
    await user.click(courseFilter)

    const allCoursesOption = await screen.findByText('All Courses')
    await user.click(allCoursesOption)

    expect(onCourseChange).toHaveBeenCalled()
  })

  it('calls onRoleChange when role filter changes', async () => {
    const user = userEvent.setup()
    const onCourseChange = vi.fn()
    const onRoleChange = vi.fn()

    renderWithQueryClient(
      <PeopleFilters
        selectedCourse="all"
        selectedRole="all"
        onCourseChange={onCourseChange}
        onRoleChange={onRoleChange}
      />,
    )

    const roleFilter = screen.getByTestId('role-filter-select')
    await user.click(roleFilter)

    const teacherOption = await screen.findByText('Teacher')
    await user.click(teacherOption)

    expect(onRoleChange).toHaveBeenCalled()
  })

  it('displays all role options', async () => {
    const user = userEvent.setup()
    const onCourseChange = vi.fn()
    const onRoleChange = vi.fn()

    renderWithQueryClient(
      <PeopleFilters
        selectedCourse="all"
        selectedRole="all"
        onCourseChange={onCourseChange}
        onRoleChange={onRoleChange}
      />,
    )

    const roleFilter = screen.getByTestId('role-filter-select')
    await user.click(roleFilter)

    expect(await screen.findByText('All Roles')).toBeInTheDocument()
    expect(screen.getByText('Teacher')).toBeInTheDocument()
    expect(screen.getByText('Teaching Assistant')).toBeInTheDocument()
  })
})
