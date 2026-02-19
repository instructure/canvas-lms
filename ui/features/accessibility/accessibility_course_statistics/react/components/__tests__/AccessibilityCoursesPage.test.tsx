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
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {MemoryRouter} from 'react-router-dom'
import {AccessibilityCoursesPage} from '../AccessibilityCoursesPage'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {createMockCourses, createMockLinkHeaderString} from '../../../__tests__/factories'

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

  const renderPage = (initialEntries: string[] = ['/']) =>
    render(
      <MemoryRouter initialEntries={initialEntries}>
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

  describe('pagination', () => {
    it('loads page from URL query parameter on mount', async () => {
      let lastRequestParams: URLSearchParams | undefined

      const mockCourses = createMockCourses(14)
      server.use(
        http.get('/api/v1/accounts/123/courses', ({request}: {request: Request}) => {
          lastRequestParams = new URL(request.url).searchParams
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(3)},
          })
        }),
      )

      renderPage(['/?page=2'])

      await waitFor(() => {
        expect(lastRequestParams?.get('page')).toBe('2')
      })
    })

    it('does not show pagination when only one page exists', async () => {
      const mockCourses = createMockCourses(5)
      server.use(
        http.get('/api/v1/accounts/123/courses', () => {
          return HttpResponse.json(mockCourses, {
            headers: {
              Link: createMockLinkHeaderString(1),
            },
          })
        }),
      )

      renderPage()

      await waitFor(() => {
        expect(screen.queryByTestId('courses-pagination')).not.toBeInTheDocument()
      })
    })

    it('shows pagination when multiple pages exist', async () => {
      const mockCourses = createMockCourses(15)
      server.use(
        http.get('/api/v1/accounts/123/courses', () => {
          return HttpResponse.json(mockCourses, {
            headers: {
              Link: createMockLinkHeaderString(2),
            },
          })
        }),
      )

      renderPage()

      await waitFor(() => {
        expect(screen.getByTestId('courses-pagination')).toBeInTheDocument()
      })
    })

        it('updates page when pagination button is clicked', async () => {
      const user = userEvent.setup()
      let lastRequestParams: URLSearchParams | undefined

      const mockCourses = createMockCourses(14)
      server.use(
        http.get('/api/v1/accounts/123/courses', ({request}: {request: Request}) => {
          lastRequestParams = new URL(request.url).searchParams
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(3)},
          })
        }),
      )

      renderPage()

      await waitFor(() => {
        expect(screen.getByTestId('courses-pagination')).toBeInTheDocument()
      })

      const page2Button = await screen.findByRole('button', {name: '2'})
      await user.click(page2Button)

      await waitFor(() => {
        expect(lastRequestParams?.get('page')).toBe('2')
      })
    })

    it('resets to page 1 when sorting changes', async () => {
      const user = userEvent.setup()
      let lastRequestParams: URLSearchParams | undefined

      const mockCourses = createMockCourses(14)
      server.use(
        http.get('/api/v1/accounts/123/courses', ({request}: {request: Request}) => {
          lastRequestParams = new URL(request.url).searchParams
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(3)},
          })
        }),
      )

      renderPage()

      await waitFor(() => {
        expect(screen.getByTestId('courses-pagination')).toBeInTheDocument()
      })

      const page2Button = await screen.findByRole('button', {name: '2'})
      await user.click(page2Button)

      const issuesHeader = await screen.findByText('Issues')
      await user.click(issuesHeader)

      await waitFor(() => {
        expect(lastRequestParams?.get('page')).toBe('1')
        expect(lastRequestParams?.get('sort')).toBe('a11y_active_issue_count')
      })
    })

    it('defaults to page 1 when invalid page number is in URL', async () => {
      let lastRequestParams: URLSearchParams | undefined

      const mockCourses = createMockCourses(14)
      server.use(
        http.get('/api/v1/accounts/123/courses', ({request}: {request: Request}) => {
          lastRequestParams = new URL(request.url).searchParams
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(3)},
          })
        }),
      )

      renderPage(['/?page=invalid'])

      await waitFor(() => {
        expect(lastRequestParams?.get('page')).toBe('1')
      })
    })

    it('defaults to page 1 when negative page number is in URL', async () => {
      let lastRequestParams: URLSearchParams | undefined

      const mockCourses = createMockCourses(14)
      server.use(
        http.get('/api/v1/accounts/123/courses', ({request}: {request: Request}) => {
          lastRequestParams = new URL(request.url).searchParams
          return HttpResponse.json(mockCourses, {
            headers: {Link: createMockLinkHeaderString(3)},
          })
        }),
      )

      renderPage(['/?page=-1'])

      await waitFor(() => {
        expect(lastRequestParams?.get('page')).toBe('1')
      })
    })
  })
})
