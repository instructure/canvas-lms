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
import ProgressOverviewWidget from '../ProgressOverviewWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'

const mockWidget: Widget = {
  id: 'test-progress-overview',
  type: 'progress_overview',
  position: {col: 1, row: 1, relative: 1},
  title: 'Progress overview',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const setup = (props: Partial<BaseWidgetProps> = {}) => {
  const defaultProps = buildDefaultProps(props)
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false},
      mutations: {retry: false},
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardEditProvider>
        <WidgetLayoutProvider>
          <ProgressOverviewWidget {...defaultProps} />
        </WidgetLayoutProvider>
      </WidgetDashboardEditProvider>
    </QueryClientProvider>,
  )
}

describe('ProgressOverviewWidget', () => {
  it('renders widget with placeholder content', () => {
    setup()
    expect(screen.getByTestId('progress-overview-placeholder')).toBeInTheDocument()
    expect(screen.getByText('Progress overview widget coming soon...')).toBeInTheDocument()
  })

  it('renders widget title', () => {
    setup()
    expect(screen.getByText('Progress overview')).toBeInTheDocument()
  })

  it('renders widget container', () => {
    setup()
    expect(screen.getByTestId('widget-test-progress-overview')).toBeInTheDocument()
  })
})
