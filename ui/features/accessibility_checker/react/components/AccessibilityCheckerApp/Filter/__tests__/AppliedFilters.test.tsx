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
import AppliedFilters from '../AppliedFilters'
import {AppliedFilter, FilterOption} from '../../../../types'

describe('AppliedFilters', () => {
  const mockSetFilters = jest.fn()

  const mockAppliedFilters: AppliedFilter[] = [
    {
      key: 'workflowStates',
      option: {value: 'published', label: 'Published'} as FilterOption,
    },
    {
      key: 'fromDate',
      option: {
        value: new Date('2023-01-01').toISOString(),
        label: 'January 1, 2023',
      } as FilterOption,
    },
  ]

  it('renders all applied filters', () => {
    render(<AppliedFilters appliedFilters={mockAppliedFilters} setFilters={mockSetFilters} />)

    expect(screen.getByText('Published')).toBeInTheDocument()
    expect(screen.getByText('January 1, 2023')).toBeInTheDocument()
  })

  it('calls setFilters with updated filters when a filter is dismissed', () => {
    render(<AppliedFilters appliedFilters={mockAppliedFilters} setFilters={mockSetFilters} />)

    const statusFilter = screen.getByText('Published').closest('button')
    fireEvent.click(statusFilter!)

    expect(mockSetFilters).toHaveBeenCalledWith({
      fromDate: {value: new Date('2023-01-01').toISOString(), label: 'January 1, 2023'},
    })
  })

  it('formats date filters correctly', () => {
    render(<AppliedFilters appliedFilters={mockAppliedFilters} setFilters={mockSetFilters} />)

    expect(screen.getByText('January 1, 2023')).toBeInTheDocument()
  })
})
