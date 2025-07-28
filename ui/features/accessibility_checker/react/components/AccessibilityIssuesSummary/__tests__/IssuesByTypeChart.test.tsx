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
import '@testing-library/jest-dom'
import {IssuesByTypeChart} from '../IssuesByTypeChart'
import {AccessibilityData, ContentItem, Severity} from '../../../types'

// Mock ResizeObserver since it's not supported in jsdom
class ResizeObserver {
  observe() {}
  disconnect() {}
  unobserve() {}
}
window.ResizeObserver = ResizeObserver

const sampleData: AccessibilityData = {
  pages: {
    1: {
      severity: 'Medium' as Severity,
      issues: [
        {ruleId: 'img-alt', displayName: 'Image alt text'},
        {ruleId: 'img-alt', displayName: 'Image alt text'},
      ],
    } as ContentItem,
  },
  attachments: {
    2: {
      severity: 'Low',
      issues: [
        {ruleId: 'img-alt', displayName: 'Image alt text'},
        {ruleId: 'table-caption', displayName: 'Table caption'},
      ],
    } as ContentItem,
    3: {
      severity: 'High',
      issues: [{ruleId: 'img-alt', displayName: 'Image alt text'}],
    } as ContentItem,
  },
}

describe('IssuesByTypeChart', () => {
  it('renders chart heading', () => {
    render(<IssuesByTypeChart accessibilityIssues={sampleData} isLoading={false} />)
    expect(screen.getByText('Issues by type')).toBeInTheDocument()
  })

  it('renders chart region with aria-label', () => {
    render(<IssuesByTypeChart accessibilityIssues={sampleData} isLoading={false} />)
    const chart = screen.getByTestId('issues-by-type-chart')
    expect(chart).toBeInTheDocument()
    expect(chart).toHaveAttribute(
      'aria-label',
      'Issues by type chart. High: 4 issues, Medium: 0 issues, Low: 1 issues.',
    )
  })

  it('handles empty data gracefully', () => {
    render(<IssuesByTypeChart accessibilityIssues={null} isLoading={false} />)
    const chart = screen.getByTestId('issues-by-type-chart')
    expect(chart).toBeInTheDocument()
    expect(chart).toHaveAttribute(
      'aria-label',
      'Issues by type chart. High: 0 issues, Medium: 0 issues, Low: 0 issues.',
    )
  })

  it('renders loading state', () => {
    render(<IssuesByTypeChart accessibilityIssues={null} isLoading={true} />)
    expect(screen.getByText('Loading accessibility issues')).toBeInTheDocument()
  })
})
