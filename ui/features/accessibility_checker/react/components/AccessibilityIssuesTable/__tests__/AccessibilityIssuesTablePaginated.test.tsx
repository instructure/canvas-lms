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
import AccessibilityIssuesTablePaginated from '../AccessibilityIssuesTablePaginated'
import {ContentItem, ContentItemType} from '../../../types'

describe('AccessibilityIssuesTablePaginated', () => {
  const testData: ContentItem[] = [
    {
      id: 1,
      title: 'Test Wiki Page 1',
      type: ContentItemType.WikiPage,
      published: true,
      updatedAt: '2025-06-03T00:00:00Z',
      count: 0,
      url: '/wiki_page_1',
      issues: [],
    },
    {
      id: 2,
      title: 'Test Assignment 1',
      type: ContentItemType.Assignment,
      published: true,
      updatedAt: '2025-06-04T00:00:00Z',
      count: 0,
      url: '/assignment_1',
      issues: [],
    },
    {
      id: 3,
      title: 'Test Assignment 2',
      type: ContentItemType.Assignment,
      published: false,
      updatedAt: '2025-06-08T00:00:00Z',
      count: 0,
      url: '/assignment_2',
      issues: [],
    },
  ]
  const paginationComponentTestId = 'accessibility-issues-table-pagination'
  const mockOnRowClick = jest.fn()
  const mockOnSortRequest = jest.fn()
  const defaultProps = {
    isLoading: false,
    error: null,
    onRowClick: mockOnRowClick,
    onSortRequest: mockOnSortRequest,
    tableData: testData,
    tableSortState: {},
    perPage: 2,
  }

  it('renders loading state', () => {
    render(<AccessibilityIssuesTablePaginated {...defaultProps} isLoading={true} />)
    const loadingElements = screen.getAllByText(/Loading accessibility issues/i)
    expect(loadingElements).toHaveLength(2)
    expect(screen.getByTestId(paginationComponentTestId)).toBeInTheDocument()
  })

  it('renders error state', () => {
    render(<AccessibilityIssuesTablePaginated {...defaultProps} error="Error loading data" />)
    expect(screen.getByText(/error loading data/i)).toBeInTheDocument()
  })

  it('renders data and pagination correctly when there are multiple pages', () => {
    render(<AccessibilityIssuesTablePaginated {...defaultProps} />)
    const row1 = screen.getByText('Test Wiki Page 1')
    const row2 = screen.getByText('Test Assignment 1')
    const rows = screen.getAllByTestId(/^issue-row-/)
    expect(row1).toBeInTheDocument()
    expect(row2).toBeInTheDocument()
    expect(rows).toHaveLength(2)
    expect(screen.getByTestId(paginationComponentTestId)).toBeInTheDocument()
  })

  it('handles page change', () => {
    render(<AccessibilityIssuesTablePaginated {...defaultProps} />)
    const buttons = screen.getAllByText(/2/i)
    fireEvent.click(buttons[2])
    const row3 = screen.getByText('Test Assignment 2')
    const rows = screen.getAllByTestId(/^issue-row-/)
    expect(row3).toBeInTheDocument()
    expect(rows).toHaveLength(1)
    expect(screen.getByTestId(paginationComponentTestId)).toBeInTheDocument()
  })

  it('pagination is not rendered when not needed', () => {
    render(<AccessibilityIssuesTablePaginated {...defaultProps} perPage={3} />)
    const row1 = screen.getByText('Test Wiki Page 1')
    const row2 = screen.getByText('Test Assignment 1')
    const row3 = screen.getByText('Test Assignment 2')
    const rows = screen.getAllByTestId(/^issue-row-/)
    expect(row1).toBeInTheDocument()
    expect(row2).toBeInTheDocument()
    expect(row3).toBeInTheDocument()
    expect(rows).toHaveLength(3)
    expect(screen.queryByTestId('accessibility-issues-table-pagination')).not.toBeInTheDocument()
  })

  it('displays the correct number of pages', () => {
    render(<AccessibilityIssuesTablePaginated {...defaultProps} perPage={1} />)
    const buttonPage3 = screen.getAllByText(/3/i)[1]
    expect(buttonPage3).toBeInTheDocument()
  })
})
