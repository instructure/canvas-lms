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
import {render, screen, fireEvent} from '@testing-library/react'
import FiltersPopover from '../FiltersPopover'
import {issueTypeOptions} from '../../../../constants'

describe('FiltersPopover', () => {
  let liveRegion = null
  const mockOnFilterChange = jest.fn()
  const defaultProps = {
    onFilterChange: mockOnFilterChange,
    appliedFilters: [],
  }
  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the FiltersPopover button', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    expect(button).toBeInTheDocument()
  })

  it('opens the popover when the button is clicked', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    fireEvent.click(button)
    expect(screen.getByTestId('filters-popover-header')).toBeInTheDocument()
  })

  it('closes the popover when the Close button is clicked', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    fireEvent.click(button)
    const closeButton = screen.getByText('Close Filter Popover')
    fireEvent.click(closeButton)
    expect(screen.queryByTestId('filters-popover-header')).not.toBeInTheDocument()
  })

  it('calls onFilterChange with the selected filters when the popover is closed', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    fireEvent.click(button)
    const closeButton = screen.getByText('Close Filter Popover')
    fireEvent.click(closeButton)
    expect(mockOnFilterChange).toHaveBeenCalledWith({
      ruleTypes: [{label: 'all', value: 'all'}],
      artifactTypes: [{label: 'all', value: 'all'}],
      workflowStates: [{label: 'all', value: 'all'}],
      fromDate: null,
      toDate: null,
    })
  })

  it('resets the filters when the Reset button is clicked', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    fireEvent.click(button)
    const resetButton = screen.getByTestId('reset-button')
    fireEvent.click(resetButton)
    expect(mockOnFilterChange).toHaveBeenCalledWith(null)
  })

  it('updates the selected filters when dropdowns are changed', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    fireEvent.click(button)

    const issueTypeDropdown = screen.getByTestId('issue-type-dropdown')
    fireEvent.change(issueTypeDropdown, {target: {value: issueTypeOptions[1].value}})
    expect(mockOnFilterChange).not.toHaveBeenCalled() // Filters are updated only on close
  })

  it('updates the date range when date inputs are changed', () => {
    render(<FiltersPopover {...defaultProps} />)
    const button = screen.getByTestId('filters-popover-button')
    fireEvent.click(button)

    const fromDateInput = screen.getByPlaceholderText(/From/i)
    fireEvent.change(fromDateInput, {target: {value: '2025-07-01'}})
    const toDateInput = screen.getByPlaceholderText(/To/i)
    fireEvent.change(toDateInput, {target: {value: '2025-07-28'}})

    expect(mockOnFilterChange).not.toHaveBeenCalled() // Filters are updated only on close
  })
})
