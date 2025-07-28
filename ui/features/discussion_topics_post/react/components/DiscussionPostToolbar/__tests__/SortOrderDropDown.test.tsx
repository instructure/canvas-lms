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
import { render, screen, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import SortOrderDropDown from '../SortOrderDropDown'

describe('SortOrderDropDown', () => {
  const mockOnSortClick = jest.fn()

  const renderComponent = (isLocked = false, selectedSortType = 'desc') => {
    render(
      <SortOrderDropDown
        isLocked={isLocked}
        selectedSortType={selectedSortType}
        onSortClick={mockOnSortClick}
      />
    )
  }

  it('renders correctly', () => {
    renderComponent()
    expect(screen.getByTestId('sort-order-dropdown')).toBeInTheDocument()
  })

  it('displays the correct default sort type', () => {
    renderComponent()
    expect(screen.getByDisplayValue('Newest First')).toBeInTheDocument()
  })

  it('calls onSortClick when a new sort type is selected', () => {
    renderComponent()
    fireEvent.click(screen.getByTestId('sort-order-select'))
    fireEvent.click(screen.getByTestId('sort-order-select-option-asc'))
    expect(mockOnSortClick).toHaveBeenCalled()
  })

  it('updates the sort type when a new option is selected', () => {
    renderComponent()
    fireEvent.click(screen.getByTestId('sort-order-select'))
    fireEvent.click(screen.getByTestId('sort-order-select-option-asc'))
    expect(screen.getByDisplayValue('Oldest First')).toBeInTheDocument()
  })

  it('is disabled when isLocked is true', () => {
    renderComponent(true)
    expect(screen.getByTestId('sort-order-select')).toBeDisabled()
  })
})
