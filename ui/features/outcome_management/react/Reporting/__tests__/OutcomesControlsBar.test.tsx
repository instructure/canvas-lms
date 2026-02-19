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

import {render, screen} from '@testing-library/react'
import OutcomesControlsBar from '../OutcomesControlsBar'
import type {MasteryFilter} from '../types'

describe('OutcomesControlsBar', () => {
  const defaultProps = {
    search: '',
    onSearchChangeHandler: jest.fn(),
    onSearchClearHandler: jest.fn(),
    masteryFilter: 'all' as MasteryFilter,
    onMasteryFilterChange: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('search input', () => {
    it('renders search component', () => {
      render(<OutcomesControlsBar {...defaultProps} />)
      expect(screen.getByTestId('search-input')).toBeInTheDocument()
    })

    it('renders search input with correct placeholder', () => {
      render(<OutcomesControlsBar {...defaultProps} />)
      const searchInput = screen.getByTestId('search-input')
      expect(searchInput).toHaveAttribute('placeholder', 'Search...')
    })

    it('renders search input with correct screen reader label', () => {
      render(<OutcomesControlsBar {...defaultProps} />)
      const searchInput = screen.getByTestId('search-input')
      expect(searchInput).toHaveAccessibleName('Search outcomes')
    })

    it('displays the current search value', () => {
      render(<OutcomesControlsBar {...defaultProps} search="test search" />)
      const searchInput = screen.getByTestId('search-input') as HTMLInputElement
      expect(searchInput.value).toBe('test search')
    })

    it('does not display clear button when search is empty', () => {
      render(<OutcomesControlsBar {...defaultProps} search="" />)
      const clearButton = screen.queryByTestId('clear-search-icon')
      expect(clearButton).not.toBeInTheDocument()
    })

    it('displays clear button when search has value', () => {
      render(<OutcomesControlsBar {...defaultProps} search="test" />)
      const clearButton = screen.getByTestId('clear-search-icon')
      expect(clearButton).toBeInTheDocument()
    })

    it('search input has type="search"', () => {
      render(<OutcomesControlsBar {...defaultProps} />)
      const searchInput = screen.getByTestId('search-input') as HTMLInputElement
      expect(searchInput.type).toBe('search')
    })
  })

  describe('mastery filter', () => {
    it('renders mastery filter dropdown', () => {
      render(<OutcomesControlsBar {...defaultProps} />)
      expect(screen.getByTestId('mastery-filter-select')).toBeInTheDocument()
    })

    it('displays "Not Started" when not_started filter is selected', () => {
      render(<OutcomesControlsBar {...defaultProps} masteryFilter="not_started" />)
      const filterSelect = screen.getByTestId('mastery-filter-select') as HTMLInputElement
      expect(filterSelect.value).toBe('Not Started')
    })

    it('has correct screen reader label', () => {
      render(<OutcomesControlsBar {...defaultProps} />)
      expect(screen.getByLabelText('Filter by mastery')).toBeInTheDocument()
    })
  })
})
