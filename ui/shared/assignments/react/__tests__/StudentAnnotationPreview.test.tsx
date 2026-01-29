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
import StudentAnnotationPreview from '../StudentAnnotationPreview'
import {Submission} from '../AssignmentsPeerReviewsStudentTypes'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'

const server = setupServer()

const renderWithQueryClient = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  const result = render(
    <MockedQueryClientProvider client={queryClient}>{component}</MockedQueryClientProvider>,
  )
  return {
    ...result,
    rerender: (rerenderComponent: React.ReactElement) =>
      result.rerender(
        <MockedQueryClientProvider client={queryClient}>
          {rerenderComponent}
        </MockedQueryClientProvider>,
      ),
  }
}

describe('StudentAnnotationPreview', () => {
  const createSubmission = (overrides = {}): Submission => ({
    _id: '123',
    attempt: 1,
    submissionType: 'student_annotation',
    ...overrides,
  })

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  describe('successful canvadoc session', () => {
    it('renders iframe with canvadoc session URL', async () => {
      const mockSessionUrl = 'https://canvadocs.example.com/session/abc123'
      server.use(
        http.post('/api/v1/canvadoc_session', () =>
          HttpResponse.json({canvadocs_session_url: mockSessionUrl}),
        ),
      )

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        const iframe = screen.getByTestId('canvadocs-iframe')
        expect(iframe).toBeInTheDocument()
        expect(iframe).toHaveAttribute('src', mockSessionUrl)
      })
    })

    it('makes API call with correct submission attempt', async () => {
      let requestBody: any
      server.use(
        http.post('/api/v1/canvadoc_session', async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          })
        }),
      )

      renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission({attempt: 3})} />,
      )

      await waitFor(() => {
        expect(requestBody).toEqual({
          submission_attempt: 3,
          submission_id: '123',
        })
      })
    })

    it('makes API call with submission_id from submission._id', async () => {
      let requestBody: any
      server.use(
        http.post('/api/v1/canvadoc_session', async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          })
        }),
      )

      renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission({_id: '456'})} />,
      )

      await waitFor(() => {
        expect(requestBody).toEqual({
          submission_attempt: 1,
          submission_id: '456',
        })
      })
    })

    it('iframe has correct title for accessibility', async () => {
      server.use(
        http.post('/api/v1/canvadoc_session', () =>
          HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          }),
        ),
      )

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        const iframe = screen.getByTestId('canvadocs-iframe')
        expect(iframe).toHaveAttribute('title', 'Document to annotate')
      })
    })

    it('iframe has allowFullScreen attribute', async () => {
      server.use(
        http.post('/api/v1/canvadoc_session', () =>
          HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          }),
        ),
      )

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        const iframe = screen.getByTestId('canvadocs-iframe')
        expect(iframe).toHaveAttribute('allowFullScreen')
      })
    })

    it('iframe has correct CSS classes', async () => {
      server.use(
        http.post('/api/v1/canvadoc_session', () =>
          HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          }),
        ),
      )

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        const iframe = screen.getByTestId('canvadocs-iframe')
        expect(iframe).toHaveClass('ef-file-preview-frame', 'annotated-document-submission')
      })
    })
  })

  describe('error state', () => {
    it('shows error message when canvadoc session fetch fails', async () => {
      server.use(http.post('/api/v1/canvadoc_session', () => new HttpResponse(null, {status: 500})))

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        expect(screen.getByTestId('canvadoc-error')).toBeInTheDocument()
        expect(screen.getByText('There was an error loading the document.')).toBeInTheDocument()
      })
    })

    it('does not render iframe when there is an error', async () => {
      server.use(http.post('/api/v1/canvadoc_session', () => new HttpResponse(null, {status: 500})))

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        expect(screen.queryByTestId('canvadocs-iframe')).not.toBeInTheDocument()
      })
    })
  })

  describe('submission changes', () => {
    it('fetches new canvadoc session when submission._id changes', async () => {
      let callCount = 0
      let lastRequestBody: any
      server.use(
        http.post('/api/v1/canvadoc_session', async ({request}) => {
          callCount++
          lastRequestBody = await request.json()
          const url =
            callCount === 1
              ? 'https://canvadocs.example.com/session/abc123'
              : 'https://canvadocs.example.com/session/xyz789'
          return HttpResponse.json({canvadocs_session_url: url})
        }),
      )

      const {rerender} = renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission()} />,
      )

      await waitFor(() => {
        expect(callCount).toBe(1)
      })

      rerender(<StudentAnnotationPreview submission={createSubmission({_id: '456'})} />)

      await waitFor(() => {
        expect(callCount).toBe(2)
        expect(lastRequestBody).toEqual({
          submission_attempt: 1,
          submission_id: '456',
        })
      })
    })

    it('fetches new canvadoc session when submission.attempt changes', async () => {
      let callCount = 0
      let lastRequestBody: any
      server.use(
        http.post('/api/v1/canvadoc_session', async ({request}) => {
          callCount++
          lastRequestBody = await request.json()
          return HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          })
        }),
      )

      const {rerender} = renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission()} />,
      )

      await waitFor(() => {
        expect(callCount).toBe(1)
      })

      rerender(<StudentAnnotationPreview submission={createSubmission({attempt: 2})} />)

      await waitFor(() => {
        expect(callCount).toBe(2)
        expect(lastRequestBody).toEqual({
          submission_attempt: 2,
          submission_id: '123',
        })
      })
    })

    it('does not fetch new session when unrelated props change', async () => {
      let callCount = 0
      server.use(
        http.post('/api/v1/canvadoc_session', () => {
          callCount++
          return HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          })
        }),
      )

      const {rerender} = renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission()} />,
      )

      await waitFor(() => {
        expect(callCount).toBe(1)
      })

      rerender(
        <StudentAnnotationPreview submission={createSubmission({submittedAt: '2025-01-23'})} />,
      )

      await waitFor(() => {
        // Should still only be called once
        expect(callCount).toBe(1)
      })
    })
  })

  describe('component structure', () => {
    it('renders container with correct test id', async () => {
      server.use(
        http.post('/api/v1/canvadoc_session', () =>
          HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          }),
        ),
      )

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        expect(screen.getByTestId('canvadocs-pane')).toBeInTheDocument()
      })
    })

    it('applies secondary background to container', async () => {
      server.use(
        http.post('/api/v1/canvadoc_session', () =>
          HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          }),
        ),
      )

      renderWithQueryClient(<StudentAnnotationPreview submission={createSubmission()} />)

      await waitFor(() => {
        const container = screen.getByTestId('canvadocs-pane')
        expect(container).toBeInTheDocument()
      })
    })
  })

  describe('attempt value handling', () => {
    it('uses attempt 0 when provided', async () => {
      let requestBody: any
      server.use(
        http.post('/api/v1/canvadoc_session', async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          })
        }),
      )

      renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission({attempt: 0})} />,
      )

      await waitFor(() => {
        expect(requestBody).toEqual({
          submission_attempt: 0,
          submission_id: '123',
        })
      })
    })

    it('uses positive attempt numbers', async () => {
      let requestBody: any
      server.use(
        http.post('/api/v1/canvadoc_session', async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            canvadocs_session_url: 'https://canvadocs.example.com/session/abc123',
          })
        }),
      )

      renderWithQueryClient(
        <StudentAnnotationPreview submission={createSubmission({attempt: 5})} />,
      )

      await waitFor(() => {
        expect(requestBody).toEqual({
          submission_attempt: 5,
          submission_id: '123',
        })
      })
    })
  })
})
