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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import CourseGradesWidget from '../CourseGradesWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {defaultGraphQLHandlers} from '../../../../__tests__/testHelpers'

const mockWidget: Widget = {
  id: 'test-course-grades-widget',
  type: 'course_grades',
  position: {col: 1, row: 1},
  size: {width: 1, height: 1},
  title: 'Course Grades',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const renderWithQueryClient = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return render(<QueryClientProvider client={queryClient}>{component}</QueryClientProvider>)
}

const server = setupServer(...defaultGraphQLHandlers)

describe('CourseGradesWidget', () => {
  let originalEnv: any

  beforeAll(() => {
    // Set up Canvas ENV with current_user_id
    originalEnv = window.ENV
    window.ENV = {
      ...originalEnv,
      current_user_id: '123',
    }

    server.listen({
      onUnhandledRequest: 'error',
    })
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // Restore original ENV
    window.ENV = originalEnv
  })

  it('renders basic widget', () => {
    renderWithQueryClient(<CourseGradesWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Course Grades')).toBeInTheDocument()
  })
})
