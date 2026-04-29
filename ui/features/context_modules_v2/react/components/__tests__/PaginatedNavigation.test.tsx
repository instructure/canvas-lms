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

import {render, screen, fireEvent} from '@testing-library/react'
import PaginatedNavigation from '../PaginatedNavigation'

describe('PaginatedNavigation', () => {
  const defaultProps = {
    isLoading: false,
    currentPage: 1,
    onPageChange: vi.fn(),
    visiblePageInfo: {
      start: 1,
      end: 10,
      total: 45,
      totalPages: 5,
    },
  }

  it('renders pagination component with correct props', () => {
    render(<PaginatedNavigation {...defaultProps} />)

    expect(screen.getByLabelText('Module items pagination')).toBeInTheDocument()
    expect(screen.getByText('Showing 1-10 of 45 items')).toBeInTheDocument()
  })

  it('does not render if totalPages <= 1', () => {
    const props = {
      ...defaultProps,
      visiblePageInfo: {
        ...defaultProps.visiblePageInfo,
        totalPages: 1,
      },
    }

    render(<PaginatedNavigation {...props} />)

    expect(screen.queryByLabelText('Module items pagination')).not.toBeInTheDocument()
  })

  it('shows correct item range for different pages', () => {
    const {rerender} = render(
      <PaginatedNavigation
        {...defaultProps}
        currentPage={3}
        visiblePageInfo={{start: 21, end: 30, total: 45, totalPages: 5}}
      />,
    )

    expect(screen.getByText('Showing 21-30 of 45 items')).toBeInTheDocument()

    rerender(
      <PaginatedNavigation
        {...defaultProps}
        currentPage={5}
        visiblePageInfo={{start: 41, end: 45, total: 45, totalPages: 5}}
      />,
    )

    expect(screen.getByText('Showing 41-45 of 45 items')).toBeInTheDocument()
  })

  it('calls onPageChange with expected arguments when page is clicked', () => {
    const onPageChange = vi.fn()
    render(<PaginatedNavigation {...defaultProps} onPageChange={onPageChange} />)

    const page2Button = screen.getByText('2')
    fireEvent.click(page2Button)

    expect(onPageChange).toHaveBeenCalledWith(2, 1)
  })

  it('shows a spinner when loading', () => {
    render(<PaginatedNavigation {...defaultProps} isLoading={true} />)
    expect(screen.getByTitle('Loading module items...')).toBeInTheDocument()
  })

  it('handles edge case where current page shows partial items', () => {
    render(
      <PaginatedNavigation
        {...defaultProps}
        currentPage={3}
        visiblePageInfo={{start: 21, end: 25, total: 25, totalPages: 3}}
      />,
    )

    expect(screen.getByText('Showing 21-25 of 25 items')).toBeInTheDocument()
  })
})
