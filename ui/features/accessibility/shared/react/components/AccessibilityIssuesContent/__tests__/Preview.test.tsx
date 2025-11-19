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
import {
  AccessibilityIssue,
  FormValue,
  IssueWorkflowState,
  PreviewResponse,
  ResourceType,
} from '../../../types'
import Preview, {PreviewHandle} from '../Preview'
import doFetchApi from '@canvas/do-fetch-api-effect'

// Mock dependencies
jest.mock('@canvas/do-fetch-api-effect')

const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

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

  beforeEach(() => {
    jest.clearAllMocks()
    jest.resetAllMocks()
  })

  describe('initial render and loading', () => {
    it('shows loading spinner initially', () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: mockResponse,
      })

      render(<Preview {...defaultProps} />)

      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
    })

    it('shows loading overlay with spinner during API calls', async () => {
      // Create a promise that we can control
      let resolvePromise: (value: any) => void
      const pendingPromise = new Promise(resolve => {
        resolvePromise = resolve
      })

      // @ts-expect-error
      mockDoFetchApi.mockReturnValue(pendingPromise)

      render(<Preview {...defaultProps} />)

      // Should show loading spinner initially
      expect(screen.getByText('Loading preview...')).toBeInTheDocument()

      // Should have the overlay mask
      expect(document.getElementById('a11y-issue-preview-overlay')).toBeInTheDocument()

      // Resolve the promise to complete the loading
      resolvePromise!({
        json: {
          content: '<div>Test content</div>',
          path: '//div',
        },
      })

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

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: mockResponse,
      })

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      // Wait for initial load to complete
      await waitFor(() => {
        expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()
      })

      // Create a promise for the update operation
      let resolveUpdatePromise: (value: any) => void
      const updatePromise = new Promise(resolve => {
        resolveUpdatePromise = resolve
      })

      // @ts-expect-error
      mockDoFetchApi.mockReturnValueOnce(updatePromise)

      // Trigger update
      const formValue: FormValue = {value: 'test-value'}
      ref.current?.update(formValue)

      // Should show loading spinner during update
      expect(screen.getByText('Loading preview...')).toBeInTheDocument()
      expect(document.getElementById('a11y-issue-preview-overlay')).toBeInTheDocument()

      // Resolve the update promise
      resolveUpdatePromise!({
        json: mockResponse,
      })

      // Wait for loading to complete
      await waitFor(() => {
        expect(screen.queryByText('Loading preview...')).not.toBeInTheDocument()
      })
    })

    it('calls API on mount with correct parameters', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: mockResponse,
      })

      render(<Preview {...defaultProps} />)

      const expectedParams = new URLSearchParams({
        issue_id: '1',
      })

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: `/preview?${expectedParams.toString()}`,
          method: 'GET',
        })
      })
    })

    it('handles API error gracefully and shows error alert', async () => {
      mockDoFetchApi.mockRejectedValue(new Error('API Error'))

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
      })
    })

    it('hides loading overlay when not loading and no error', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: mockResponse,
      })

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
      // Create a promise that we can control
      let resolvePromise: (value: any) => void
      const pendingPromise = new Promise(resolve => {
        resolvePromise = resolve
      })

      // @ts-expect-error
      mockDoFetchApi.mockReturnValue(pendingPromise)

      render(<Preview {...defaultProps} />)

      // Should show loading spinner with correct title
      const loadingSpinner = screen.getByText('Loading preview...')
      expect(loadingSpinner).toBeInTheDocument()

      // The spinner should be inside the overlay mask
      const overlay = document.getElementById('a11y-issue-preview-overlay')
      expect(overlay).toBeInTheDocument()
      expect(overlay).toContainElement(loadingSpinner)

      // Clean up
      resolvePromise!({
        json: {
          content: '<div>Test content</div>',
          path: '//div',
        },
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
        json: mockResponse,
      })

      render(<Preview {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Test content')).toBeInTheDocument()
      })
    })

    it('handles missing path in response', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: undefined,
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: mockResponse,
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
        json: mockResponse,
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
        json: mockResponse,
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
          path: '/preview',
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
        json: mockResponse,
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
        json: mockResponse,
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
    it('renders one time when issue changes', async () => {
      const mockResponse: PreviewResponse = {
        content: '<div>Test content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValue({
        json: mockResponse,
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
        expect(mockDoFetchApi).toHaveBeenCalled()
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

      render(<Preview {...defaultProps} itemType={ResourceType.WikiPage} />)

      const expectedParams = new URLSearchParams({
        issue_id: '1',
      })

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: `/preview?${expectedParams.toString()}`,
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

      render(<Preview {...defaultProps} itemType={ResourceType.Attachment} />)

      const expectedParams = new URLSearchParams({
        issue_id: '1',
      })

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: `/preview?${expectedParams.toString()}`,
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
        json: mockResponse,
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

  describe('error state management', () => {
    it('clears error state when successful API call follows error', async () => {
      // First call fails
      mockDoFetchApi.mockRejectedValueOnce({})

      const ref = React.createRef<PreviewHandle>()
      render(<Preview {...defaultProps} ref={ref} />)

      await waitFor(() => {
        expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
      })

      // Second call succeeds
      const mockResponse: PreviewResponse = {
        content: '<div>Success content</div>',
        path: '//div',
      }

      // @ts-expect-error
      mockDoFetchApi.mockResolvedValueOnce({
        json: mockResponse,
      })

      ref.current?.update({value: 'a'})

      await waitFor(() => {
        expect(
          screen.queryByText('Error previewing fixed accessibility issue.'),
        ).not.toBeInTheDocument()
      })
    })
  })

  it('clears error when itemId changes', async () => {
    const mockResponse: PreviewResponse = {
      content: '<div>Test content</div>',
      path: '//div',
    }

    // First call fails
    mockDoFetchApi.mockRejectedValueOnce({})

    const {rerender} = render(<Preview {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Error previewing fixed accessibility issue.')).toBeInTheDocument()
    })

    // @ts-expect-error
    mockDoFetchApi.mockResolvedValueOnce({
      json: mockResponse,
    })

    rerender(<Preview {...defaultProps} resourceId={2} />)

    await waitFor(() => {
      expect(
        screen.queryByText('Error previewing fixed accessibility issue.'),
      ).not.toBeInTheDocument()
    })
  })
})
