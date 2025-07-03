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
import {AccessibilityIssue, ContentItemType, FormValue, PreviewResponse} from '../../../types'
import Preview, {PreviewHandle} from '../Preview'
import doFetchApi from '@canvas/do-fetch-api-effect'

// Mock dependencies
jest.mock('@canvas/do-fetch-api-effect')

const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

describe('Preview', () => {
  const mockIssue: AccessibilityIssue = {
    id: '1',
    ruleId: 'adjacent-links',
    path: '//div[@class="test-element"]',
    message: 'Test accessibility issue',
    why: 'This is why it is an issue',
    element: 'div',
    form: {
      type: 'textinput' as any,
      label: 'Test label',
      value: 'test value',
    },
  }

  const defaultProps = {
    issue: mockIssue,
    itemId: 123,
    itemType: 'Assignment' as ContentItemType,
  }

  beforeEach(() => {
    jest.clearAllMocks()
    jest.resetAllMocks()
  })

  describe('initial render and loading', () => {
    it('shows loading spinner initially', () => {
      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve({content: '<div>Test content</div>', path: '//div'}),
      })

      render(<Preview {...defaultProps} />)

      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
    })

    it('calls API on mount with correct parameters', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: 'http://localhost//preview?content_type=Assignment&content_id=123',
          method: 'GET',
        })
      })
    })

    it('handles API error gracefully and shows error alert', async () => {
      mockDoFetchApi.mockRejectedValue(new Error('API Error'))

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(
          screen.getByText('Error loading preview for accessibility issue'),
        ).toBeInTheDocument()
      })
    })
  })

  describe('content rendering', () => {
    it('renders content after successful API call', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div class="test-element">Test content</div>',
        path: '//div[@class="test-element"]',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })
    })

    it('applies highlight styling to target element', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div class="test-element">Test content</div>',
        path: '//div[@class="test-element"]',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        const previewContainer = screen.getByText('Test content').closest('div')
        expect(previewContainer).toHaveAttribute('data-a11y-issue-scroll-target')
        expect(previewContainer).toHaveStyle('outline-offset: 2px;')
      })
    })

    it('handles missing path in response', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: undefined,
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })
    })
  })

  describe('ref functionality', () => {
    it('exposes update method through ref', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Updated content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
        expect(typeof ref.current?.update).toBe('function')
      })
    })

    it('calls update API with correct parameters', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Updated content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
      })

      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: 'http://localhost//preview',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            content_id: 123,
            content_type: 'Assignment',
            rule: 'adjacent-links',
            path: '//div[@class="test-element"]',
            value: formValue,
          }),
        })
      })
    })

    it('shows loading state during update', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Updated content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(ref.current).toBeDefined()
      })

      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue)

      // Should show loading spinner during update
      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
    })

    it('calls onSuccess callback when update succeeds', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Updated content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

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
      mockDoFetchApi.mockRejectedValue(new Error('Update failed'))

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
    it('re-renders when issue changes', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      const {rerender} = render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })

      const newIssue: AccessibilityIssue = {
        ...mockIssue,
        id: '2',
        path: '//span[@class="new-element"]',
      }

      rerender(<Preview {...defaultProps} issue={newIssue} />)

      // Should call API again with new issue
      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledTimes(2)
      })
    })

    it('handles different content types', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Page content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} itemType={ContentItemType.WikiPage} />)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: 'http://localhost//preview?content_type=Page&content_id=123',
          method: 'GET',
        })
      })
    })

    it('handles attachment content type', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Attachment content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} itemType={ContentItemType.Attachment} />)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: 'http://localhost//preview?content_type=attachment&content_id=123',
          method: 'GET',
        })
      })
    })
  })

  describe('DOM structure', () => {
    it('renders with correct container attributes', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

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

  describe('highlight functionality', () => {
    it('preserves existing styles when applying highlight', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div class="test-element" style="color: rgb(255, 0, 0);">Test content</div>',
        path: '//div[@class="test-element"]',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        const previewContainer = screen.getByText('Test content').closest('div')
        expect(previewContainer).toHaveStyle('outline-offset: 2px;')
      })
    })

    it('encodes issue path in data attribute', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div class="test-element">Test content</div>',
        path: '//div[@class="test-element"]',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: Promise.resolve(mockResponse),
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        const previewContainer = screen.getByText('Test content').closest('div')
        const encodedPath = encodeURIComponent('//div[@class="test-element"]')
        expect(previewContainer).toHaveAttribute('data-a11y-issue-scroll-target', encodedPath)
      })
    })
  })

  describe('error state management', () => {
    it('clears error state when successful API call follows error', async () => {
      // First call fails
      mockDoFetchApi.mockRejectedValueOnce({})

      const {rerender} = render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(
          screen.getByText('Error loading preview for accessibility issue'),
        ).toBeInTheDocument()
      })

      // Second call succeeds
      const mockResponse: PreviewResponse = {
        content: '<div>Success content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValueOnce({
        json: Promise.resolve(mockResponse),
      })

      const newIssue: AccessibilityIssue = {
        ...mockIssue,
        id: '2',
      }

      rerender(<Preview {...defaultProps} issue={newIssue} />)

      await waitFor(() => {
        expect(
          screen.queryByText('Error loading preview for accessibility issue'),
        ).not.toBeInTheDocument()
      })
    })
  })
})
