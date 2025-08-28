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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import PeopleWidget from '../PeopleWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'

const mockWidget: Widget = {
  id: 'test-people-widget',
  type: 'people',
  position: {col: 1, row: 1},
  size: {width: 1, height: 1},
  title: 'Test People Widget',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const renderWithQueryClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
}

describe('PeopleWidget', () => {
  beforeAll(() => {
    window.ENV = {
      current_user_id: '123',
      GRAPHQL_URL: '/api/graphql',
      CSRF_TOKEN: 'mock-csrf-token',
    } as any
  })

  it('renders widget title', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
    expect(screen.getByText('Test People Widget')).toBeInTheDocument()
  })

  it('handles external loading state', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps({isLoading: true})} />)
    expect(screen.getByText('Loading people data...')).toBeInTheDocument()
  })

  it('handles external error state', () => {
    const onRetry = jest.fn()
    renderWithQueryClient(
      <PeopleWidget {...buildDefaultProps({error: 'Failed to load', onRetry})} />,
    )

    expect(screen.getByText('Failed to load')).toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Retry'})).toBeInTheDocument()
  })

  it('renders internal loading state when no external props provided', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
    expect(screen.getByText('Loading people data...')).toBeInTheDocument()
  })

  it('has correct data-testid', () => {
    renderWithQueryClient(<PeopleWidget {...buildDefaultProps()} />)
    expect(screen.getByTestId('widget-test-people-widget')).toBeInTheDocument()
  })
})
