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
import {setupServer} from 'msw/node'
import {http, HttpResponse, delay} from 'msw'
import {
  AccessibilityIssue,
  FormValue,
  IssueWorkflowState,
  PreviewResponse,
  ResourceType,
} from '../../../types'
import Preview, {PreviewHandle} from '../Preview'

const server = setupServer()

describe('Preview', () => {
  const mockIssue: AccessibilityIssue = {
    id: '1',
    ruleId: 'adjacent-links',
    displayName: 'Duplicate links',
    path: '//div[@class="test-element"]',
    message: 'Test accessibility issue',
    why: 'This is why it is an issue',
    element: 'div',
    workflowState: IssueWorkflowState.Active,
    form: {
      type: 'textinput' as any,
      label: 'Test label',
      value: 'test value',
    },
  }

  const defaultProps = {
    issue: mockIssue,
    resourceId: 123,
    itemType: ResourceType.Assignment,
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('initial render and loading', () => {
    it('shows loading spinner initially', () => {
      server.use(
        http.get('/preview', async () => {
          await delay(100)
          return HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          })
        }),
      )

      render(<Preview {...defaultProps} />)

      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
    })

    it('shows loading overlay with spinner during API calls', async () => {
      server.use(
        http.get('/preview', async () => {
          await delay(50)
          return HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          })
        }),
      )

      render(<Preview {...defaultProps} />)

      // Should show loading spinner initially
      expect(screen.getByText('Loading preview...')).toBeInTheDocument()

      // Should have the overlay mask
      expect(document.getElementById('a11y-issue-preview-overlay')).toBeInTheDocument()

      // Wait for loading to complete
      await waitFor(() => {
        expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()
      })
    })

    it('shows loading overlay during update operations', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Updated content</div>',
        path: '//div',
      }

      let requestCount = 0
      server.use(
        http.get('/preview', () => HttpResponse.json(mockResponse)),
        http.post('/preview', async () => {
          requestCount++
          if (requestCount === 1) {
            await delay(50)
          }
          return HttpResponse.json(mockResponse)
        }),
      )

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      // Wait for initial load to complete
      await waitFor(() => {
        expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()
      })

      // Trigger update
      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue)

      // Should show loading spinner during update
      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
      expect(document.getElementById('a11y-issue-preview-overlay')).toBeInTheDocument()

      // Wait for loading to complete
      await waitFor(() => {
        expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()
      })
    })

    it('calls API on mount with correct parameters', async () => {
      let capturedUrl = ''
      server.use(
        http.get('/preview', ({request}) => {
          capturedUrl = request.url
          return HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          })
        }),
      )

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(capturedUrl).toContain('/preview')
        expect(capturedUrl).toContain('issue_id=1')
      })
    })

    it('handles API error gracefully and shows error alert', async () => {
      server.use(http.get('/preview', () => HttpResponse.error()))

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
      })
    })

    it('hides loading overlay when not loading and no error', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          }),
        ),
      )

      render(<Preview {...defaultProps} />)

      // Wait for loading to complete
      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })

      // Should not show loading spinner
      expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()

      // Should not have the overlay mask
      expect(document.getElementById('a11y-issue-preview-overlay')).not.toBeInTheDocument()
    })

    it('shows loading spinner with correct accessibility attributes', () => {
      server.use(
        http.get('/preview', async () => {
          await delay(100)
          return HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          })
        }),
      )

      render(<Preview {...defaultProps} />)

      // Should show loading spinner with correct title
      const loadingSpinner = screen.getByText('Loading preview...')
      expect(loadingSpinner).toBeInTheDocument()

      // The spinner should be inside the overlay mask
      const overlay = document.getElementById('a11y-issue-preview-overlay')
      expect(overlay).toBeInTheDocument()
      expect(overlay).toContainElement(loadingSpinner)
    })
  })

  describe('content rendering', () => {
    it('renders content after successful API call', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div class="test-element">Test content</div>',
            path: '//div[@class="test-element"]',
          }),
        ),
      )

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })
    })

    it('handles missing path in response', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Test content</div>',
            path: undefined,
          }),
        ),
      )

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })
    })
  })

  describe('ref functionality', () => {
    it('exposes update method through ref', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          }),
        ),
      )

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
        expect(typeof ref.current?.update).toBe('function')
      })
    })

    it('calls update API with correct parameters', async () => {
      let capturedBody: any = null
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          }),
        ),
        http.post('/preview', async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          })
        }),
      )

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
      })

      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue)

      await waitFor(() => {
        expect(capturedBody).toEqual({
          content_id: 123,
          content_type: 'Assignment',
          rule: 'adjacent-links',
          path: '//div[@class="test-element"]',
          value: formValue,
        })
      })
    })

    it('shows loading state during update', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          }),
        ),
        http.post('/preview', async () => {
          await delay(50)
          return HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          })
        }),
      )

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
      })

      // Wait for initial load to complete
      await waitFor(() => {
        expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()
      })

      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue)

      // Should show loading spinner during update
      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
    })

    it('calls onSuccess callback when update succeeds', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          }),
        ),
        http.post('/preview', () =>
          HttpResponse.json({
            content: '<div>Updated content</div>',
            path: '//div',
          }),
        ),
      )

      const ref = React.createRef<PreviewHandle>()
      const onSuccess = jest.fn()
      const onError = jest.fn()

      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
      })

      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue, onSuccess, onError)

      await waitFor(() => {
        expect(onSuccess).toHaveBeenCalledTimes(1)
        expect(onError).not.toHaveBeenCalled()
      })
    })

    it('calls onError callback when update fails', async () => {
      server.use(
        http.get('/preview', () => HttpResponse.error()),
        http.post('/preview', () => HttpResponse.error()),
      )

      const ref = React.createRef<PreviewHandle>()
      const onSuccess = jest.fn()
      const onError = jest.fn()

      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
      })

      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue, onSuccess, onError)

      await waitFor(() => {
        expect(onError).toHaveBeenCalledTimes(1)
        expect(onSuccess).not.toHaveBeenCalled()
      })
    })
  })

  describe('component props', () => {
    it('renders one time when issue changes', async () => {
      let requestCount = 0
      server.use(
        http.get('/preview', () => {
          requestCount++
          return HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          })
        }),
      )

      const {rerender} = render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })

      const initialCount = requestCount

      const newIssue: AccessibilityIssue = {
        ...mockIssue,
        id: '2',
        path: '//span[@class="new-element"]',
      }

      rerender(<Preview {...defaultProps} issue={newIssue} />)

      // Should call API again with new issue
      await waitFor(() => {
        expect(requestCount).toBeGreaterThan(initialCount)
      })
    })

    it('handles different content types', async () => {
      let capturedUrl = ''
      server.use(
        http.get('/preview', ({request}) => {
          capturedUrl = request.url
          return HttpResponse.json({
            content: '<div>Page content</div>',
            path: '//div',
          })
        }),
      )

      render(<Preview {...defaultProps} itemType={ResourceType.WikiPage} />)

      await waitFor(() => {
        expect(capturedUrl).toContain('/preview')
        expect(capturedUrl).toContain('issue_id=1')
      })
    })

    it('handles attachment content type', async () => {
      let capturedUrl = ''
      server.use(
        http.get('/preview', ({request}) => {
          capturedUrl = request.url
          return HttpResponse.json({
            content: '<div>Attachment content</div>',
            path: '//div',
          })
        }),
      )

      render(<Preview {...defaultProps} itemType={ResourceType.Attachment} />)

      await waitFor(() => {
        expect(capturedUrl).toContain('/preview')
        expect(capturedUrl).toContain('issue_id=1')
      })
    })
  })

  describe('DOM structure', () => {
    it('renders with correct container attributes', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          }),
        ),
      )

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        const container = screen.getByText('Test content').closest('#a11y-issue-preview')
        expect(container).toBeInTheDocument()
        expect(container).toHaveStyle({
          height: '15rem',
          overflowY: 'auto',
        })
      })
    })
  })

  describe('error state management', () => {
    it('clears error state when successful API call follows error', async () => {
      let requestCount = 0
      server.use(
        http.get('/preview', () => {
          requestCount++
          if (requestCount === 1) {
            return HttpResponse.error()
          }
          return HttpResponse.json({
            content: '<div>Success content</div>',
            path: '//div',
          })
        }),
        http.post('/preview', () =>
          HttpResponse.json({
            content: '<div>Success content</div>',
            path: '//div',
          }),
        ),
      )

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
      })

      ref.current?.update({value: 'a'})

      await waitFor(() => {
        expect(
          screen.queryByText('Error previewing fixed accessibility issue.'),
        ).not.toBeInTheDocument()
      })
    })

    it('displays content when error response includes content', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json(
            {
              content: '<div>Error content</div>',
              path: '//div',
              error: 'Element not found for path: invalid_path',
            },
            {status: 400},
          ),
        ),
      )

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(screen.getByText('Error content')).toBeInTheDocument()
      })

      expect(
        screen.queryByText('Error previewing fixed accessibility issue.'),
      ).not.toBeInTheDocument()
    })

    it('shows error overlay when error response has no content', async () => {
      server.use(
        http.get('/preview', () =>
          HttpResponse.json(
            {
              error: 'Something went wrong',
            },
            {status: 400},
          ),
        ),
      )

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
      })
    })

    it('clears error when itemId changes', async () => {
      let requestCount = 0
      server.use(
        http.get('/preview', () => {
          requestCount++
          if (requestCount === 1) {
            return HttpResponse.error()
          }
          return HttpResponse.json({
            content: '<div>Test content</div>',
            path: '//div',
          })
        }),
      )

      const {rerender} = render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
      })

      rerender(<Preview {...defaultProps} resourceId={2} />)

      await waitFor(() => {
        expect(
          screen.queryByText('Error previewing fixed accessibility issue.'),
        ).not.toBeInTheDocument()
      })
    })
  })
})
