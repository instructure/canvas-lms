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

import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable'
import {ContentItem, ContentItemType} from '../../../types'

describe('AccessibilityIssuesTable', () => {
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
  ]

  it('renders without crashing', () => {
    render(<AccessibilityIssuesTable tableData={[]} />)
    expect(screen.getByTestId('accessibility-issues-table')).toBeInTheDocument()
  })

  it('displays the correct number of rows', () => {
    render(<AccessibilityIssuesTable tableData={testData} />)
    expect(screen.getAllByTestId(/^issue-row-/)).toHaveLength(testData.length)
  })

  it('calls onSortRequest with the proper arguments when a column header is clicked', () => {
    const mockOnSortRequest = jest.fn()

    const {rerender} = render(
      <AccessibilityIssuesTable onSortRequest={mockOnSortRequest} tableData={testData} />,
    )

    screen.getByText('Content Type').click()
    expect(mockOnSortRequest).toHaveBeenCalledWith('content-type-header', 'ascending')
    rerender(
      <AccessibilityIssuesTable
        onSortRequest={mockOnSortRequest}
        tableData={testData}
        tableSortState={{sortId: 'content-type-header', sortDirection: 'ascending'}}
      />,
    )
    screen.getByText('Content Type').click()
    expect(mockOnSortRequest).toHaveBeenCalledWith('content-type-header', 'descending')
    rerender(
      <AccessibilityIssuesTable
        onSortRequest={mockOnSortRequest}
        tableData={testData}
        tableSortState={{sortId: 'content-type-header', sortDirection: 'descending'}}
      />,
    )
    screen.getByText('Content Type').click()
    expect(mockOnSortRequest).toHaveBeenCalledWith('content-type-header', 'none')
  })
})
