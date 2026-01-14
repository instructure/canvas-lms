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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {FilterWrapper} from '../FilterWrapper'
import {Pagination} from '../../../types/rollup'

const mockPagination: Pagination = {
  currentPage: 1,
  totalPages: 5,
  totalCount: 100,
  perPage: 20,
}

const defaultProps = {
  pagination: mockPagination,
  onPerPageChange: vi.fn(),
}

describe('FilterWrapper', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders FilterWrapper with all components when pagination is provided', () => {
    render(<FilterWrapper {...defaultProps} />)

    expect(screen.getByText('100 students,')).toBeInTheDocument()
    expect(screen.getByTestId('per-page-selector')).toBeInTheDocument()
  })

  it('does not render content when pagination is undefined', () => {
    const {container} = render(<FilterWrapper {...defaultProps} pagination={undefined} />)
    expect(container.querySelector('[data-testid="per-page-selector"]')).not.toBeInTheDocument()
    expect(screen.queryByText('100 students,')).not.toBeInTheDocument()
  })

  it('renders TotalStudentText with correct total count', () => {
    render(<FilterWrapper {...defaultProps} />)

    expect(screen.getByText('100 students,')).toBeInTheDocument()
  })

  it('renders StudentPerPageSelector with correct value', () => {
    render(<FilterWrapper {...defaultProps} />)

    const selector = screen.getByTestId('per-page-selector')
    expect(selector).toBeInTheDocument()
  })

  it('calls onPerPageChange when per page value changes', async () => {
    const onPerPageChange = vi.fn()
    render(<FilterWrapper {...defaultProps} onPerPageChange={onPerPageChange} />)

    const selector = screen.getByTestId('per-page-selector')
    await userEvent.click(selector)

    const option50 = screen.getByText('50')
    await userEvent.click(option50)

    expect(onPerPageChange).toHaveBeenCalledWith(50)
  })
})
