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
import {render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {MemoryRouter} from 'react-router-dom'
import {AccessibilityCoursesPage} from '../AccessibilityCoursesPage'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {createMockCourses} from '../../../__tests__/factories'

const server = setupServer()

describe('AccessibilityCoursesPage', () => {
  let queryClient: QueryClient

  beforeAll(() => {
    server.listen()
    window.ENV = {ACCOUNT_ID: '123'} as any
  })

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })

  afterAll(() => {
    server.close()
  })

  const renderPage = () =>
    render(
      <MemoryRouter>
        <QueryClientProvider client={queryClient}>
          <AccessibilityCoursesPage />
        </QueryClientProvider>
      </MemoryRouter>,
    )

  it('renders the page heading', () => {
    server.use(
      http.get('/api/v1/accounts/123/courses', () => {
        return HttpResponse.json([])
      }),
    )

    renderPage()
    expect(screen.getByRole('heading', {name: 'Accessibility report'})).toBeInTheDocument()
  })

  it('shows loading spinner initially', () => {
    server.use(
      http.get('/api/v1/accounts/123/courses', async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return HttpResponse.json([])
      }),
    )

    renderPage()
    expect(screen.getByTitle('Loading courses')).toBeInTheDocument()
  })

  it('displays courses table when data is loaded', async () => {
    const mockCourses = createMockCourses(2)
    server.use(
      http.get('/api/v1/accounts/123/courses', () => {
        return HttpResponse.json(mockCourses) // API returns array directly
      }),
    )

    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Course 0')).toBeInTheDocument()
      expect(screen.getByText('Course 1')).toBeInTheDocument()
    })
  })

  it('shows empty state when no courses are found', async () => {
    server.use(
      http.get('/api/v1/accounts/123/courses', () => {
        return HttpResponse.json([])
      }),
    )

    renderPage()

    await waitFor(() => {
      expect(screen.getByText('No courses found')).toBeInTheDocument()
    })
  })

  it('shows error page on API failure', async () => {
    server.use(
      http.get('/api/v1/accounts/123/courses', () => {
        return HttpResponse.json({errors: [{message: 'Server error'}]}, {status: 500})
      }),
    )

    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('displays courses in table format with correct columns', async () => {
    const mockCourses = createMockCourses(2)
    server.use(
      http.get('/api/v1/accounts/123/courses', () => {
        return HttpResponse.json(mockCourses) // API returns array directly
      }),
    )

    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Course')).toBeInTheDocument()
      expect(screen.getByText('Issues')).toBeInTheDocument()
      expect(screen.getByText('Resolved')).toBeInTheDocument()
      expect(screen.getByText('Term')).toBeInTheDocument()
      expect(screen.getByText('Teacher')).toBeInTheDocument()
      expect(screen.getByText('Sub-Account')).toBeInTheDocument()
      expect(screen.getByText('Students')).toBeInTheDocument()
    })
  })
})
