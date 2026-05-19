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
import {render, screen, waitFor, act} from '@testing-library/react'
import PeerReviewSelector from '../PeerReviewSelector'

describe('PeerReviewSelector', () => {
  const defaultProps = {
    assignmentDueDate: '2024-11-20T23:59:00Z',
    assignmentUntilDate: '2024-11-30T23:59:00Z',
    setPeerReviewAvailableToDate: vi.fn(),
    setPeerReviewAvailableFromDate: vi.fn(),
    peerReviewDueDate: null,
    setPeerReviewDueDate: vi.fn(),
    handlePeerReviewDueDateChange: vi.fn(),
    validationErrors: {},
    unparsedFieldKeys: new Set<string>(),
    dateInputRefs: {},
    timeInputRefs: {},
    handleBlur: vi.fn(() => vi.fn()),
    breakpoints: {},
    clearButtonAltLabel: 'Clear due date for 2 students',
  }

  let mockCheckbox: HTMLInputElement
  const originalENV = window.ENV
  const originalRequestAnimationFrame = window.requestAnimationFrame

  beforeEach(() => {
    vi.clearAllMocks()

    // jsdom doesn't execute requestAnimationFrame callbacks
    window.requestAnimationFrame = (callback: FrameRequestCallback) => {
      callback(0)
      return 0
    }

    window.ENV = {
      ...originalENV,
      PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED: true,
    }

    mockCheckbox = document.createElement('input')
    mockCheckbox.type = 'checkbox'
    mockCheckbox.id = 'assignment_peer_reviews_checkbox'
    mockCheckbox.checked = true
    document.body.appendChild(mockCheckbox)
  })

  afterEach(() => {
    window.ENV = originalENV
    window.requestAnimationFrame = originalRequestAnimationFrame
    if (mockCheckbox && mockCheckbox.parentNode) {
      document.body.removeChild(mockCheckbox)
    }
  })

  const renderComponent = (overrides = {}) =>
    render(<PeerReviewSelector {...defaultProps} {...overrides} />)

  describe('visibility conditions', () => {
    it('renders when PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED is true and checkbox is checked', () => {
      renderComponent()
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
      expect(screen.queryByText('Reviewing Starts')).not.toBeInTheDocument()
      expect(screen.queryByText('Until')).not.toBeInTheDocument()
    })

    it('does not render when PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED is false', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false
      renderComponent()
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('does not render when checkbox is not checked', () => {
      mockCheckbox.checked = false
      renderComponent()
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('does not render when checkbox does not exist', () => {
      document.body.removeChild(mockCheckbox)
      renderComponent()
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })
  })

  describe('peerReviewsEnabled prop (Assign To modal context)', () => {
    it('renders when checkbox does not exist and peerReviewsEnabled is true', () => {
      document.body.removeChild(mockCheckbox)
      renderComponent({peerReviewsEnabled: true})
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
      expect(screen.queryByText('Reviewing Starts')).not.toBeInTheDocument()
      expect(screen.queryByText('Until')).not.toBeInTheDocument()
    })

    it('does not render when checkbox does not exist and peerReviewsEnabled is false', () => {
      document.body.removeChild(mockCheckbox)
      renderComponent({peerReviewsEnabled: false})
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('does not render when checkbox does not exist and peerReviewsEnabled is undefined', () => {
      document.body.removeChild(mockCheckbox)
      renderComponent({peerReviewsEnabled: undefined})
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('updates visibility when peerReviewsEnabled changes from false to true', async () => {
      document.body.removeChild(mockCheckbox)
      const {rerender} = renderComponent({peerReviewsEnabled: false})
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()

      rerender(<PeerReviewSelector {...defaultProps} peerReviewsEnabled={true} />)

      await waitFor(() => {
        expect(screen.getByText('Review Due Date')).toBeInTheDocument()
      })
    })

    it('updates visibility when peerReviewsEnabled changes from true to false', async () => {
      document.body.removeChild(mockCheckbox)
      const {rerender} = renderComponent({peerReviewsEnabled: true})
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()

      rerender(<PeerReviewSelector {...defaultProps} peerReviewsEnabled={false} />)

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
      })
    })

    it('checkbox checked state takes precedence over peerReviewsEnabled when checkbox exists', () => {
      mockCheckbox.checked = false
      renderComponent({peerReviewsEnabled: true})
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })
  })

  describe('child component rendering', () => {
    it('renders only the Review Due Date input', () => {
      renderComponent()
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
      expect(screen.queryByText('Reviewing Starts')).not.toBeInTheDocument()
      expect(screen.queryByText('Until')).not.toBeInTheDocument()
    })

    it('passes correct props to PeerReviewDueDateTimeInput', () => {
      const peerReviewDueDate = '2024-11-18T00:00:00Z'
      const setPeerReviewDueDate = vi.fn()
      const handlePeerReviewDueDateChange = vi.fn()

      const {container} = renderComponent({
        peerReviewDueDate,
        setPeerReviewDueDate,
        handlePeerReviewDueDateChange,
      })

      expect(
        container.querySelector('[data-testid="peer_review_due_at_input"]'),
      ).toBeInTheDocument()
    })

    it('does not render PeerReviewAvailableFromDateTimeInput', () => {
      const {container} = renderComponent()

      expect(
        container.querySelector('[data-testid="peer_review_available_from_input"]'),
      ).not.toBeInTheDocument()
    })

    it('does not render PeerReviewAvailableToDateTimeInput', () => {
      const {container} = renderComponent()

      expect(
        container.querySelector('[data-testid="peer_review_available_to_input"]'),
      ).not.toBeInTheDocument()
    })

    it('passes clearButtonAltLabel to due date component', () => {
      renderComponent()
      expect(screen.getByText('Clear due date for 2 students')).toBeInTheDocument()
      expect(screen.queryByText('Clear available from for 2 students')).not.toBeInTheDocument()
      expect(screen.queryByText('Clear available to for 2 students')).not.toBeInTheDocument()
    })
  })

  describe('disabled state', () => {
    it('disables the due date input when assignmentDueDate is null', () => {
      renderComponent({assignmentDueDate: null})
      const clearButton = screen.getByText('Clear').closest('button')
      expect(clearButton).toBeDisabled()
    })

    it('enables the due date input when assignmentDueDate is set', () => {
      renderComponent({assignmentDueDate: '2024-11-20T23:59:00Z'})
      const clearButton = screen.getByText('Clear').closest('button')
      expect(clearButton).not.toBeDisabled()
    })
  })

  describe('checkbox change event listener', () => {
    it('shows inputs when checkbox is checked', async () => {
      mockCheckbox.checked = false
      const {rerender} = renderComponent()

      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()

      act(() => {
        mockCheckbox.checked = true
        mockCheckbox.dispatchEvent(new Event('change'))
      })

      rerender(<PeerReviewSelector {...defaultProps} />)

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).toBeInTheDocument()
      })
    })

    it('hides inputs when checkbox is unchecked', async () => {
      const {rerender} = renderComponent()

      expect(screen.getByText('Review Due Date')).toBeInTheDocument()

      act(() => {
        mockCheckbox.checked = false
        mockCheckbox.dispatchEvent(new Event('change'))
      })

      rerender(<PeerReviewSelector {...defaultProps} />)

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
      })
    })
  })

  describe('message event listener', () => {
    it('updates state when ASGMT.togglePeerReviews message is received', async () => {
      mockCheckbox.checked = false
      const {rerender} = renderComponent()

      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()

      await act(async () => {
        mockCheckbox.checked = true
        window.postMessage({subject: 'ASGMT.togglePeerReviews', enabled: true}, '*')
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      rerender(<PeerReviewSelector {...defaultProps} />)

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).toBeInTheDocument()
      })
    })

    it('does not update state for unrelated messages', async () => {
      mockCheckbox.checked = false
      renderComponent()

      await act(async () => {
        window.postMessage({subject: 'SOME_OTHER_MESSAGE'}, '*')
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('hides inputs when ASGMT.togglePeerReviews message with enabled: false is received', async () => {
      renderComponent()
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()

      await act(async () => {
        window.postMessage({subject: 'ASGMT.togglePeerReviews', enabled: false}, '*')
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
      })
    })

    it('shows inputs when ASGMT.togglePeerReviews message with enabled: true is received and checkbox is checked', async () => {
      mockCheckbox.checked = true
      const {rerender} = renderComponent()

      await act(async () => {
        window.postMessage({subject: 'ASGMT.togglePeerReviews', enabled: false}, '*')
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      rerender(<PeerReviewSelector {...defaultProps} />)

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
      })

      await act(async () => {
        window.postMessage({subject: 'ASGMT.togglePeerReviews', enabled: true}, '*')
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      rerender(<PeerReviewSelector {...defaultProps} />)

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).toBeInTheDocument()
      })
    })
  })

  describe('cleanup', () => {
    it('removes event listeners on unmount', () => {
      const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener')
      const checkboxRemoveListenerSpy = vi.spyOn(mockCheckbox, 'removeEventListener')

      const {unmount} = renderComponent()
      unmount()

      expect(removeEventListenerSpy).toHaveBeenCalledWith('message', expect.any(Function))
      expect(checkboxRemoveListenerSpy).toHaveBeenCalledWith('change', expect.any(Function))

      removeEventListenerSpy.mockRestore()
      checkboxRemoveListenerSpy.mockRestore()
    })
  })

  describe('clearing peer review dates', () => {
    it('clears due date and available from but not available to when assignmentDueDate becomes null', async () => {
      const setPeerReviewDueDate = vi.fn()
      const setPeerReviewAvailableFromDate = vi.fn()
      const setPeerReviewAvailableToDate = vi.fn()

      const {rerender} = renderComponent({
        assignmentDueDate: '2024-11-20T23:59:00Z',
        peerReviewDueDate: '2024-11-18T00:00:00Z',
        setPeerReviewDueDate,
        setPeerReviewAvailableFromDate,
        setPeerReviewAvailableToDate,
      })

      // Clear the mocks from initial render
      setPeerReviewDueDate.mockClear()
      setPeerReviewAvailableFromDate.mockClear()
      setPeerReviewAvailableToDate.mockClear()

      // Change assignmentDueDate to null
      rerender(
        <PeerReviewSelector
          {...defaultProps}
          assignmentDueDate={null}
          peerReviewDueDate="2024-11-18T00:00:00Z"
          setPeerReviewDueDate={setPeerReviewDueDate}
          setPeerReviewAvailableFromDate={setPeerReviewAvailableFromDate}
          setPeerReviewAvailableToDate={setPeerReviewAvailableToDate}
        />,
      )

      await waitFor(() => {
        expect(setPeerReviewDueDate).toHaveBeenCalledWith(null)
        expect(setPeerReviewAvailableFromDate).toHaveBeenCalledWith(null)
        // lock_at (available to) inherits from assignment until date and must
        // not be cleared when only the due date is cleared
        expect(setPeerReviewAvailableToDate).not.toHaveBeenCalledWith(null)
      })
    })

    it('clears all peer review dates when peer review checkbox is unchecked', async () => {
      const setPeerReviewDueDate = vi.fn()
      const setPeerReviewAvailableFromDate = vi.fn()
      const setPeerReviewAvailableToDate = vi.fn()

      const {rerender} = renderComponent({
        peerReviewDueDate: '2024-11-18T00:00:00Z',
        setPeerReviewDueDate,
        setPeerReviewAvailableFromDate,
        setPeerReviewAvailableToDate,
      })

      // Component should be visible initially
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()

      // Clear the mocks from initial render
      setPeerReviewDueDate.mockClear()
      setPeerReviewAvailableFromDate.mockClear()
      setPeerReviewAvailableToDate.mockClear()

      // Uncheck the peer review checkbox
      await act(async () => {
        mockCheckbox.checked = false
        mockCheckbox.dispatchEvent(new Event('change'))
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      rerender(
        <PeerReviewSelector
          {...defaultProps}
          peerReviewDueDate="2024-11-18T00:00:00Z"
          setPeerReviewDueDate={setPeerReviewDueDate}
          setPeerReviewAvailableFromDate={setPeerReviewAvailableFromDate}
          setPeerReviewAvailableToDate={setPeerReviewAvailableToDate}
        />,
      )

      await waitFor(() => {
        expect(setPeerReviewDueDate).toHaveBeenCalledWith(null)
        expect(setPeerReviewAvailableFromDate).toHaveBeenCalledWith(null)
        expect(setPeerReviewAvailableToDate).toHaveBeenCalledWith(null)
      })
    })
  })

  describe('prop passing', () => {
    it('passes through validation errors to the due date component', () => {
      const validationErrors = {
        peer_review_due_at: 'Due date is required',
      }

      renderComponent({
        validationErrors,
        showMessages: true,
      })

      expect(screen.getByText('Due date is required')).toBeInTheDocument()
    })

    it('passes through unparsed field keys to the due date component', () => {
      const unparsedFieldKeys = new Set(['peer_review_due_at'])

      renderComponent({
        unparsedFieldKeys,
        showMessages: true,
      })

      expect(screen.getByText('Invalid date')).toBeInTheDocument()
    })

    it('passes through breakpoints to child components', () => {
      const breakpoints = {mobileOnly: true}
      renderComponent({breakpoints})
      // Component renders without errors
    })

    it('passes through dateInputRefs to the due date component', () => {
      const dateInputRefs: Record<string, HTMLInputElement | null> = {}
      renderComponent({dateInputRefs})

      expect(dateInputRefs.peer_review_due_at).toBeDefined()
    })

    it('passes through timeInputRefs to the due date component', () => {
      const timeInputRefs: Record<string, HTMLInputElement | null> = {}
      renderComponent({timeInputRefs})

      expect(timeInputRefs.peer_review_due_at).toBeDefined()
    })
  })

  describe('auto-sync peer review dates from assignment dates', () => {
    it('sets peer review available from to assignment due date', () => {
      const setPeerReviewAvailableFromDate = vi.fn()
      renderComponent({
        assignmentDueDate: '2024-11-20T23:59:00Z',
        setPeerReviewAvailableFromDate,
      })

      expect(setPeerReviewAvailableFromDate).toHaveBeenCalledWith('2024-11-20T23:59:00Z')
    })

    it('sets peer review available to to assignment until date', () => {
      const setPeerReviewAvailableToDate = vi.fn()
      renderComponent({
        assignmentUntilDate: '2024-11-30T23:59:00Z',
        setPeerReviewAvailableToDate,
      })

      expect(setPeerReviewAvailableToDate).toHaveBeenCalledWith('2024-11-30T23:59:00Z')
    })

    it('updates peer review available from when assignment due date changes', () => {
      const setPeerReviewAvailableFromDate = vi.fn()
      const {rerender} = renderComponent({
        assignmentDueDate: '2024-11-20T23:59:00Z',
        setPeerReviewAvailableFromDate,
      })

      setPeerReviewAvailableFromDate.mockClear()

      rerender(
        <PeerReviewSelector
          {...defaultProps}
          assignmentDueDate="2024-12-01T23:59:00Z"
          setPeerReviewAvailableFromDate={setPeerReviewAvailableFromDate}
        />,
      )

      expect(setPeerReviewAvailableFromDate).toHaveBeenCalledWith('2024-12-01T23:59:00Z')
    })

    it('updates peer review available to when assignment until date changes', () => {
      const setPeerReviewAvailableToDate = vi.fn()
      const {rerender} = renderComponent({
        assignmentUntilDate: '2024-11-30T23:59:00Z',
        setPeerReviewAvailableToDate,
      })

      setPeerReviewAvailableToDate.mockClear()

      rerender(
        <PeerReviewSelector
          {...defaultProps}
          assignmentUntilDate="2024-12-15T23:59:00Z"
          setPeerReviewAvailableToDate={setPeerReviewAvailableToDate}
        />,
      )

      expect(setPeerReviewAvailableToDate).toHaveBeenCalledWith('2024-12-15T23:59:00Z')
    })

    it('sets peer review available from to null when assignment due date is null', () => {
      const setPeerReviewAvailableFromDate = vi.fn()
      renderComponent({
        assignmentDueDate: null,
        setPeerReviewAvailableFromDate,
      })

      expect(setPeerReviewAvailableFromDate).toHaveBeenCalledWith(null)
    })

    it('sets peer review available to to null when assignment until date is null', () => {
      const setPeerReviewAvailableToDate = vi.fn()
      renderComponent({
        assignmentUntilDate: null,
        setPeerReviewAvailableToDate,
      })

      expect(setPeerReviewAvailableToDate).toHaveBeenCalledWith(null)
    })
  })

  describe('clearing peer review due date', () => {
    it('clears peer review due date to null when assignment due date is cleared', async () => {
      const setPeerReviewDueDate = vi.fn()
      const setPeerReviewAvailableFromDate = vi.fn()
      const setPeerReviewAvailableToDate = vi.fn()

      const {rerender} = renderComponent({
        assignmentDueDate: '2024-11-20T23:59:00Z',
        peerReviewDueDate: '2024-11-25T00:00:00Z',
        setPeerReviewDueDate,
        setPeerReviewAvailableFromDate,
        setPeerReviewAvailableToDate,
      })

      setPeerReviewDueDate.mockClear()

      rerender(
        <PeerReviewSelector
          {...defaultProps}
          assignmentDueDate={null}
          peerReviewDueDate="2024-11-25T00:00:00Z"
          setPeerReviewDueDate={setPeerReviewDueDate}
          setPeerReviewAvailableFromDate={setPeerReviewAvailableFromDate}
          setPeerReviewAvailableToDate={setPeerReviewAvailableToDate}
        />,
      )

      await waitFor(() => {
        expect(setPeerReviewDueDate).toHaveBeenCalledWith(null)
      })
    })

    it('allows clearing peer review due date independently', () => {
      const setPeerReviewDueDate = vi.fn()

      renderComponent({
        assignmentDueDate: '2024-11-20T23:59:00Z',
        peerReviewDueDate: null,
        setPeerReviewDueDate,
      })

      // setPeerReviewDueDate should not be called with a non-null value
      // (the component does not auto-set the peer review due date)
      const nonNullCalls = setPeerReviewDueDate.mock.calls.filter(
        (args: unknown[]) => args[0] !== null,
      )
      expect(nonNullCalls).toHaveLength(0)
    })
  })
})
