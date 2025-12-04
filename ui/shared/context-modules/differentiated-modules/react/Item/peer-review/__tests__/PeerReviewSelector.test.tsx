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
    peerReviewAvailableToDate: null,
    setPeerReviewAvailableToDate: jest.fn(),
    handlePeerReviewAvailableToDateChange: jest.fn(),
    peerReviewAvailableFromDate: null,
    setPeerReviewAvailableFromDate: jest.fn(),
    handlePeerReviewAvailableFromDateChange: jest.fn(),
    peerReviewDueDate: null,
    setPeerReviewDueDate: jest.fn(),
    handlePeerReviewDueDateChange: jest.fn(),
    validationErrors: {},
    unparsedFieldKeys: new Set<string>(),
    dateInputRefs: {},
    timeInputRefs: {},
    handleBlur: jest.fn(() => jest.fn()),
    breakpoints: {},
    clearButtonAltLabels: {
      dueDateLabel: 'Clear due date for 2 students',
      availableFromLabel: 'Clear available from for 2 students',
      availableToLabel: 'Clear available to for 2 students',
    },
  }

  let mockCheckbox: HTMLInputElement
  const originalENV = window.ENV

  beforeEach(() => {
    jest.clearAllMocks()

    // Set up ENV
    window.ENV = {
      ...originalENV,
      PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED: true,
    }

    // Create and add checkbox to DOM
    mockCheckbox = document.createElement('input')
    mockCheckbox.type = 'checkbox'
    mockCheckbox.id = 'assignment_peer_reviews_checkbox'
    mockCheckbox.checked = true
    document.body.appendChild(mockCheckbox)
  })

  afterEach(() => {
    window.ENV = originalENV
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
      expect(screen.getByText('Reviewing Starts')).toBeInTheDocument()
      expect(screen.getByText('Until')).toBeInTheDocument()
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

  describe('child component rendering', () => {
    it('renders all three peer review input components', () => {
      renderComponent()
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
      expect(screen.getByText('Reviewing Starts')).toBeInTheDocument()
      expect(screen.getByText('Until')).toBeInTheDocument()
    })

    it('passes correct props to PeerReviewDueDateTimeInput', () => {
      const peerReviewDueDate = '2024-11-18T00:00:00Z'
      const setPeerReviewDueDate = jest.fn()
      const handlePeerReviewDueDateChange = jest.fn()

      const {container} = renderComponent({
        peerReviewDueDate,
        setPeerReviewDueDate,
        handlePeerReviewDueDateChange,
      })

      expect(
        container.querySelector('[data-testid="peer_review_due_at_input"]'),
      ).toBeInTheDocument()
    })

    it('passes correct props to PeerReviewAvailableFromDateTimeInput', () => {
      const peerReviewAvailableFromDate = '2024-11-10T00:00:00Z'
      const setPeerReviewAvailableFromDate = jest.fn()
      const handlePeerReviewAvailableFromDateChange = jest.fn()

      const {container} = renderComponent({
        peerReviewAvailableFromDate,
        setPeerReviewAvailableFromDate,
        handlePeerReviewAvailableFromDateChange,
      })

      expect(
        container.querySelector('[data-testid="peer_review_available_from_input"]'),
      ).toBeInTheDocument()
    })

    it('passes correct props to PeerReviewAvailableToDateTimeInput', () => {
      const peerReviewAvailableToDate = '2024-11-25T23:59:00Z'
      const setPeerReviewAvailableToDate = jest.fn()
      const handlePeerReviewAvailableToDateChange = jest.fn()

      const {container} = renderComponent({
        peerReviewAvailableToDate,
        setPeerReviewAvailableToDate,
        handlePeerReviewAvailableToDateChange,
      })

      expect(
        container.querySelector('[data-testid="peer_review_available_to_input"]'),
      ).toBeInTheDocument()
    })

    it('passes clearButtonAltLabels to child components', () => {
      renderComponent()
      expect(screen.getByText('Clear due date for 2 students')).toBeInTheDocument()
      expect(screen.getByText('Clear available from for 2 students')).toBeInTheDocument()
      expect(screen.getByText('Clear available to for 2 students')).toBeInTheDocument()
    })
  })

  describe('disabled state', () => {
    it('disables inputs when assignmentDueDate is null', () => {
      renderComponent({assignmentDueDate: null})
      const clearButtons = screen.getAllByText('Clear').map(el => el.closest('button'))

      clearButtons.forEach(button => {
        expect(button).toBeDisabled()
      })
    })

    it('enables inputs when assignmentDueDate is set', () => {
      renderComponent({assignmentDueDate: '2024-11-20T23:59:00Z'})
      const clearButtons = screen.getAllByText('Clear').map(el => el.closest('button'))

      clearButtons.forEach(button => {
        expect(button).not.toBeDisabled()
      })
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
        window.postMessage({subject: 'ASGMT.togglePeerReviews'}, '*')
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
  })

  describe('cleanup', () => {
    it('removes event listeners on unmount', () => {
      const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener')
      const checkboxRemoveListenerSpy = jest.spyOn(mockCheckbox, 'removeEventListener')

      const {unmount} = renderComponent()
      unmount()

      expect(removeEventListenerSpy).toHaveBeenCalledWith('message', expect.any(Function))
      expect(checkboxRemoveListenerSpy).toHaveBeenCalledWith('change', expect.any(Function))

      removeEventListenerSpy.mockRestore()
      checkboxRemoveListenerSpy.mockRestore()
    })
  })

  describe('clearing peer review dates', () => {
    it('clears all peer review dates when assignmentDueDate becomes null', async () => {
      const setPeerReviewDueDate = jest.fn()
      const setPeerReviewAvailableFromDate = jest.fn()
      const setPeerReviewAvailableToDate = jest.fn()

      const {rerender} = renderComponent({
        assignmentDueDate: '2024-11-20T23:59:00Z',
        peerReviewDueDate: '2024-11-18T00:00:00Z',
        peerReviewAvailableFromDate: '2024-11-10T00:00:00Z',
        peerReviewAvailableToDate: '2024-11-25T23:59:00Z',
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
          peerReviewAvailableFromDate="2024-11-10T00:00:00Z"
          peerReviewAvailableToDate="2024-11-25T23:59:00Z"
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

    it('clears all peer review dates when peer review checkbox is unchecked', async () => {
      const setPeerReviewDueDate = jest.fn()
      const setPeerReviewAvailableFromDate = jest.fn()
      const setPeerReviewAvailableToDate = jest.fn()

      const {rerender} = renderComponent({
        peerReviewDueDate: '2024-11-18T00:00:00Z',
        peerReviewAvailableFromDate: '2024-11-10T00:00:00Z',
        peerReviewAvailableToDate: '2024-11-25T23:59:00Z',
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
          peerReviewAvailableFromDate="2024-11-10T00:00:00Z"
          peerReviewAvailableToDate="2024-11-25T23:59:00Z"
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
    it('passes through validation errors to child components', () => {
      const validationErrors = {
        peer_review_due_at: 'Due date is required',
        peer_review_available_from: 'Start date is required',
        peer_review_available_to: 'End date is required',
      }

      renderComponent({
        validationErrors,
        showMessages: true,
      })

      expect(screen.getByText('Due date is required')).toBeInTheDocument()
      expect(screen.getByText('Start date is required')).toBeInTheDocument()
      expect(screen.getByText('End date is required')).toBeInTheDocument()
    })

    it('passes through unparsed field keys to child components', () => {
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

    it('passes through dateInputRefs to child components', () => {
      const dateInputRefs: Record<string, HTMLInputElement | null> = {}
      renderComponent({dateInputRefs})

      expect(dateInputRefs.peer_review_due_at).toBeDefined()
      expect(dateInputRefs.peer_review_available_from).toBeDefined()
      expect(dateInputRefs.peer_review_available_to).toBeDefined()
    })

    it('passes through timeInputRefs to child components', () => {
      const timeInputRefs: Record<string, HTMLInputElement | null> = {}
      renderComponent({timeInputRefs})

      expect(timeInputRefs.peer_review_due_at).toBeDefined()
      expect(timeInputRefs.peer_review_available_from).toBeDefined()
      expect(timeInputRefs.peer_review_available_to).toBeDefined()
    })
  })
})
