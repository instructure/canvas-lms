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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import PeerReviewDueDateTimeInput from '../PeerReviewDueDateTimeInput'

describe('PeerReviewDueDateTimeInput', () => {
  const defaultProps = {
    peerReviewDueDate: null,
    setPeerReviewDueDate: vi.fn(),
    handlePeerReviewDueDateChange: vi.fn(),
    clearButtonAltLabel: 'Clear input for 2 students',
    disabled: false,
    validationErrors: {},
    unparsedFieldKeys: new Set<string>(),
    dateInputRefs: {},
    timeInputRefs: {},
    handleBlur: vi.fn(() => vi.fn()),
    breakpoints: {},
  }

  const renderComponent = (overrides = {}) =>
    render(<PeerReviewDueDateTimeInput {...defaultProps} {...overrides} />)

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders with correct labels', () => {
    renderComponent()
    expect(screen.getByText('Review Due Date')).toBeInTheDocument()
    expect(screen.getByText('Clear')).toBeInTheDocument()
  })

  it('renders accessible label for clear button', () => {
    renderComponent()
    expect(screen.getByText('Clear input for 2 students')).toBeInTheDocument()
  })

  it('renders with null date value', () => {
    renderComponent({peerReviewDueDate: null})
    const dateInput = screen.getByLabelText('Review Due Date')
    expect(dateInput).toBeInTheDocument()
    expect(dateInput).toHaveValue('')
  })

  it('renders with a date value', () => {
    const dateValue = '2024-11-15T00:00:00Z'
    renderComponent({peerReviewDueDate: dateValue})
    const dateInput = screen.getByLabelText('Review Due Date')
    expect(dateInput).toBeInTheDocument()
  })

  it('disables clear button when disabled prop is true', () => {
    renderComponent({disabled: true})
    const clearButton = screen.getByText('Clear').closest('button')
    expect(clearButton).toBeDisabled()
  })

  it('calls setPeerReviewDueDate with null when clear button is clicked', async () => {
    const setPeerReviewDueDate = vi.fn()
    renderComponent({
      peerReviewDueDate: '2024-11-15T00:00:00Z',
      setPeerReviewDueDate,
    })

    const clearButton = screen.getByText('Clear').closest('button')
    await userEvent.click(clearButton!)
    expect(setPeerReviewDueDate).toHaveBeenCalledWith(null)
  })

  it('calls handlePeerReviewDueDateChange when date is changed', async () => {
    const handlePeerReviewDueDateChange = vi.fn()
    renderComponent({
      handlePeerReviewDueDateChange,
    })

    const dateInput = screen.getByLabelText('Review Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 15, 2024'}})
    screen.getByRole('option', {name: /16 november 2024/i}).click()

    await waitFor(() => {
      expect(handlePeerReviewDueDateChange).toHaveBeenCalled()
    })
  })

  it('calls handleBlur when input loses focus', () => {
    const handleBlur = vi.fn(() => vi.fn())
    renderComponent({handleBlur})

    expect(handleBlur).toHaveBeenCalledWith('peer_review_due_at')

    const dateInput = screen.getByLabelText('Review Due Date')
    fireEvent.blur(dateInput)
  })

  it('sets up dateInputRef correctly', () => {
    const dateInputRefs: Record<string, HTMLInputElement | null> = {}
    renderComponent({dateInputRefs})

    expect(dateInputRefs.peer_review_due_at).toBeDefined()
  })

  it('sets up timeInputRef correctly', () => {
    const timeInputRefs: Record<string, HTMLInputElement | null> = {}
    renderComponent({timeInputRefs})

    expect(timeInputRefs.peer_review_due_at).toBeDefined()
  })

  describe('validation messages', () => {
    it('displays no messages when there are no errors and field is parsed', () => {
      renderComponent({
        peerReviewDueDate: '2024-11-15T00:00:00Z',
        validationErrors: {},
        unparsedFieldKeys: new Set(),
      })

      expect(screen.queryByText('Invalid date')).not.toBeInTheDocument()
    })

    it('displays error message when validation error exists', () => {
      renderComponent({
        validationErrors: {peer_review_due_at: 'Date must be in the future'},
        showMessages: true,
      })

      expect(screen.getByText('Date must be in the future')).toBeInTheDocument()
    })

    it('displays invalid date message when field is unparsed', () => {
      const unparsedFieldKeys = new Set(['peer_review_due_at'])
      renderComponent({
        unparsedFieldKeys,
        showMessages: true,
      })

      expect(screen.getByText('Invalid date')).toBeInTheDocument()
    })

    it('prioritizes unparsed error over validation error', () => {
      const unparsedFieldKeys = new Set(['peer_review_due_at'])
      renderComponent({
        validationErrors: {peer_review_due_at: 'Date must be in the future'},
        unparsedFieldKeys,
        showMessages: true,
      })

      expect(screen.getByText('Invalid date')).toBeInTheDocument()
      expect(screen.queryByText('Date must be in the future')).not.toBeInTheDocument()
    })
  })

  describe('timezone messages', () => {
    const originalENV = window.ENV

    beforeEach(() => {
      window.ENV = {
        ...originalENV,
        TIMEZONE: 'America/New_York',
        CONTEXT_TIMEZONE: 'America/Los_Angeles',
        context_asset_string: 'course_1',
      }
    })

    afterEach(() => {
      window.ENV = originalENV
    })

    it('displays timezone hint messages when timezones differ', () => {
      renderComponent({
        peerReviewDueDate: '2024-11-15T00:00:00Z',
        showMessages: true,
      })

      expect(screen.getByText(/Local:/)).toBeInTheDocument()
      expect(screen.getByText(/Course:/)).toBeInTheDocument()
    })
  })

  it('passes through additional props to ClearableDateTimeInput', () => {
    const locale = 'en-US'
    const timezone = 'America/New_York'
    const {container} = renderComponent({
      locale,
      timezone,
    })

    expect(container.querySelector('[data-testid="peer_review_due_at_input"]')).toBeInTheDocument()
  })

  it('has correct id for the input', () => {
    const {container} = renderComponent()
    expect(container.querySelector('[data-testid="peer_review_due_at_input"]')).toBeInTheDocument()
  })

  it('renders with showMessages prop', () => {
    const {rerender, container} = renderComponent({
      showMessages: false,
      validationErrors: {peer_review_due_at: 'Some error'},
    })

    expect(container.querySelector('[class*="error"]')).toBeFalsy()

    rerender(
      <PeerReviewDueDateTimeInput
        {...defaultProps}
        showMessages={true}
        validationErrors={{peer_review_due_at: 'Some error'}}
      />,
    )
  })
})
