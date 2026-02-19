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
import {cleanup, render, screen, fireEvent} from '@testing-library/react'
import AppliedFilters from '../AppliedFilters'
import {AppliedFilter, FilterOption} from '../../../../../../shared/react/types'

describe('AppliedFilters', () => {
  afterEach(() => {
    cleanup()
  })

  const mockSetFilters = vi.fn()

  beforeEach(() => {
    mockSetFilters.mockClear()
  })

  const mockAppliedFilters: AppliedFilter[] = [
    {
      key: 'workflowStates',
      option: {value: 'published', label: 'Published'} as FilterOption,
    },
    {
      key: 'fromDate',
      option: {
        value: new Date('2023-01-01').toISOString(),
        label: 'Jan 1, 2023',
      } as FilterOption,
    },
  ]

  it('renders all applied filters', () => {
    render(<AppliedFilters appliedFilters={mockAppliedFilters} setFilters={mockSetFilters} />)

    expect(screen.getByText(/State:/)).toBeInTheDocument()
    expect(screen.getByText(/Published/)).toBeInTheDocument()
    expect(screen.getByText(/Last edited:/)).toBeInTheDocument()
    expect(screen.getByText(/Jan 1, 2023 - Today/)).toBeInTheDocument()
  })

  it('calls setFilters with updated filters when a filter is dismissed', () => {
    render(<AppliedFilters appliedFilters={mockAppliedFilters} setFilters={mockSetFilters} />)

    const statusFilter = screen.getByText(/State:/).closest('button')
    fireEvent.click(statusFilter!)

    expect(mockSetFilters).toHaveBeenCalledWith({
      fromDate: {value: new Date('2023-01-01').toISOString(), label: 'Jan 1, 2023'},
    })
  })

  it('formats date filters correctly - from date only', () => {
    render(<AppliedFilters appliedFilters={mockAppliedFilters} setFilters={mockSetFilters} />)

    expect(screen.getByText(/Last edited:/)).toBeInTheDocument()
    expect(screen.getByText(/Jan 1, 2023 - Today/)).toBeInTheDocument()
  })

  it('formats date filters correctly - both from and to dates', () => {
    const filters: AppliedFilter[] = [
      {
        key: 'fromDate',
        option: {
          value: new Date('2023-01-01').toISOString(),
          label: 'Jan 1, 2023',
        } as FilterOption,
      },
      {
        key: 'toDate',
        option: {
          value: new Date('2023-12-31').toISOString(),
          label: 'Dec 31, 2023',
        } as FilterOption,
      },
    ]
    render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

    expect(screen.getByText(/Last edited:/)).toBeInTheDocument()
    expect(screen.getByText(/Jan 1, 2023 - Dec 31, 2023/)).toBeInTheDocument()
  })

  it('formats date filters correctly - to date only', () => {
    const filters: AppliedFilter[] = [
      {
        key: 'toDate',
        option: {
          value: new Date('2023-12-31').toISOString(),
          label: 'Dec 31, 2023',
        } as FilterOption,
      },
    ]
    render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

    expect(screen.getByText(/Last edited:/)).toBeInTheDocument()
    expect(screen.getByText(/up to Dec 31, 2023/)).toBeInTheDocument()
  })

  it('dismisses both date filters when clicking date range pill', () => {
    const filters: AppliedFilter[] = [
      {
        key: 'fromDate',
        option: {
          value: new Date('2023-01-01').toISOString(),
          label: 'Jan 1, 2023',
        } as FilterOption,
      },
      {
        key: 'toDate',
        option: {
          value: new Date('2023-12-31').toISOString(),
          label: 'Dec 31, 2023',
        } as FilterOption,
      },
      {
        key: 'workflowStates',
        option: {value: 'published', label: 'Published'} as FilterOption,
      },
    ]
    render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

    const dateFilter = screen.getByText(/Last edited:/).closest('button')
    fireEvent.click(dateFilter!)

    expect(mockSetFilters).toHaveBeenCalledWith({
      workflowStates: [{value: 'published', label: 'Published'}],
    })
  })

  describe('condensed rule type filters', () => {
    it('shows single rule type filter without condensing', () => {
      const filters: AppliedFilter[] = [
        {
          key: 'ruleTypes',
          option: {value: 'alt-text', label: 'Alt text'} as FilterOption,
        },
      ]

      render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

      expect(screen.getByText(/With issues of:/)).toBeInTheDocument()
      expect(screen.getByText(/^Alt text$/)).toBeInTheDocument()
    })

    it('condenses multiple rule type filters into one pill with count', () => {
      const filters: AppliedFilter[] = [
        {
          key: 'ruleTypes',
          option: {value: 'alt-text', label: 'Alt text'} as FilterOption,
        },
        {
          key: 'ruleTypes',
          option: {value: 'heading-order', label: 'Skipped heading level'} as FilterOption,
        },
        {
          key: 'ruleTypes',
          option: {value: 'adjacent-links', label: 'Duplicate links'} as FilterOption,
        },
      ]

      render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

      expect(screen.getByText(/With issues of:/)).toBeInTheDocument()
      expect(screen.getByText(/Alt text \+2/)).toBeInTheDocument()
      expect(screen.queryByText(/Skipped heading level/)).not.toBeInTheDocument()
      expect(screen.queryByText(/Duplicate links/)).not.toBeInTheDocument()
    })

    it('dismisses all rule type filters when clicking condensed pill', () => {
      const filters: AppliedFilter[] = [
        {
          key: 'ruleTypes',
          option: {value: 'alt-text', label: 'Alt text'} as FilterOption,
        },
        {
          key: 'ruleTypes',
          option: {value: 'heading-order', label: 'Skipped heading level'} as FilterOption,
        },
        {
          key: 'workflowStates',
          option: {value: 'published', label: 'Published'} as FilterOption,
        },
      ]

      render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

      const condensedFilter = screen.getByText(/Alt text \+1/).closest('button')
      fireEvent.click(condensedFilter!)

      expect(mockSetFilters).toHaveBeenCalledWith({
        workflowStates: [{value: 'published', label: 'Published'}],
      })
    })

    it('keeps other filter types separate when condensing rule types', () => {
      const filters: AppliedFilter[] = [
        {
          key: 'ruleTypes',
          option: {value: 'alt-text', label: 'Alt text'} as FilterOption,
        },
        {
          key: 'ruleTypes',
          option: {value: 'heading-order', label: 'Skipped heading level'} as FilterOption,
        },
        {
          key: 'workflowStates',
          option: {value: 'published', label: 'Published'} as FilterOption,
        },
        {
          key: 'artifactTypes',
          option: {value: 'wiki_page', label: 'Pages'} as FilterOption,
        },
      ]

      render(<AppliedFilters appliedFilters={filters} setFilters={mockSetFilters} />)

      const pills = screen.getAllByRole('button')
      expect(pills).toHaveLength(3)

      expect(screen.getByText(/Alt text \+1/)).toBeInTheDocument()
      expect(screen.getByText(/Published/)).toBeInTheDocument()
      expect(screen.getByText(/Pages/)).toBeInTheDocument()
    })
  })
})
