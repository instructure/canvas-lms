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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import RecentGradesWidget from '../RecentGradesWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'
import {ResponsiveProvider} from '../../../../hooks/useResponsiveContext'

const mockWidget: Widget = {
  id: 'recent-grades-widget',
  type: 'recent_grades',
  position: {col: 1, row: 1, relative: 1},
  title: 'Recent grades & feedback',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const setup = (props: Partial<BaseWidgetProps> = {}, matches: string[] = ['desktop']) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })
  const defaultProps = buildDefaultProps(props)
  return render(
    <QueryClientProvider client={queryClient}>
      <ResponsiveProvider matches={matches}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>
            <RecentGradesWidget {...defaultProps} />
          </WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </ResponsiveProvider>
    </QueryClientProvider>,
  )
}

describe('RecentGradesWidget', () => {
  it('renders widget with title', () => {
    setup()
    expect(screen.getByText('Recent grades & feedback')).toBeInTheDocument()
  })

  // TODO: update when GraphQL query is integrated
  it('displays list of recent grades', () => {
    setup()
    expect(screen.getByTestId('recent-grades-list')).toBeInTheDocument()
    expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    expect(screen.getByText('Data Structures Quiz')).toBeInTheDocument()
  })

  // TODO: update when GraphQL query is integrated
  it('displays grade items with correct information', () => {
    setup()
    expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    expect(screen.getByText('CS-401')).toBeInTheDocument()
    expect(screen.getByTestId('grade-status-badge-1')).toBeInTheDocument()
    expect(screen.getByTestId('grade-status-badge-1')).toHaveTextContent('Graded')
  })

  it('displays pagination controls', async () => {
    setup()
    await waitFor(() => {
      expect(screen.getByTestId('pagination-container')).toBeInTheDocument()
    })
  })

  // TODO: update when GraphQL query is integrated
  it('paginates through grade items', async () => {
    const user = userEvent.setup()
    setup()

    expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    expect(screen.queryByText('History Presentation')).not.toBeInTheDocument()

    await waitFor(() => {
      expect(screen.getByTestId('pagination-container')).toBeInTheDocument()
    })

    const paginationContainer = screen.getByTestId('pagination-container')
    const pageButtons = paginationContainer.querySelectorAll('button')
    const page2Button = Array.from(pageButtons).find(button => button.textContent === '2')
    expect(page2Button).toBeInTheDocument()

    if (page2Button) {
      await user.click(page2Button)

      await waitFor(() => {
        expect(screen.getByText('History Presentation')).toBeInTheDocument()
        expect(screen.queryByText('Introduction to React Hooks')).not.toBeInTheDocument()
      })
    }
  })

  it('displays course filter placeholder', () => {
    setup()
    expect(screen.getByTestId('course-filter-select')).toBeInTheDocument()
    expect(screen.getByTestId('course-filter-select')).toHaveAttribute('disabled')
  })

  // TODO: update when GraphQL query is integrated
  it('displays assignment titles as text', () => {
    setup()
    const assignmentTitle = screen.getByTestId('assignment-title-1')
    expect(assignmentTitle).toBeInTheDocument()
    expect(assignmentTitle).toHaveTextContent('Introduction to React Hooks')
  })

  it('handles loading state', () => {
    setup({isLoading: true})
    expect(screen.getByText('Loading recent grades...')).toBeInTheDocument()
    expect(screen.queryByTestId('recent-grades-list')).not.toBeInTheDocument()
  })

  it('handles error state', () => {
    const onRetry = jest.fn()
    setup({error: 'Failed to load grades', onRetry})

    expect(screen.getByText('Failed to load grades')).toBeInTheDocument()
    expect(screen.getByTestId('recent-grades-widget-retry-button')).toBeInTheDocument()
  })

  it('calls onRetry when retry button is clicked', async () => {
    const user = userEvent.setup()
    const onRetry = jest.fn()
    setup({error: 'Failed to load grades', onRetry})

    const retryButton = screen.getByTestId('recent-grades-widget-retry-button')
    await user.click(retryButton)

    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  // TODO: update when GraphQL query is integrated
  it('displays correct number of items per page', () => {
    setup()
    const gradeItems = screen.getAllByTestId(/^grade-item-/)
    expect(gradeItems).toHaveLength(5)
  })

  // TODO: update when GraphQL query is integrated
  it('displays grading status badges correctly', () => {
    setup()
    const badge = screen.getByTestId('grade-status-badge-1')
    expect(badge).toHaveTextContent('Graded')
  })

  // TODO: update when GraphQL query is integrated
  it('displays timestamps for each grade', () => {
    setup()
    expect(screen.getByTestId('grade-timestamp-1')).toBeInTheDocument()
  })
})
