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
import {render} from '@testing-library/react'
import {WidgetDashboardProvider, useWidgetDashboard} from '../useWidgetDashboardContext'

const TestConsumer: React.FC = () => {
  const context = useWidgetDashboard()
  return (
    <div data-testid="test-consumer">
      <div data-testid="preferences">{JSON.stringify(context.preferences)}</div>
      <div data-testid="observed-users">{JSON.stringify(context.observedUsersList)}</div>
      <div data-testid="can-add-observee">{String(context.canAddObservee)}</div>
      <div data-testid="current-user">{JSON.stringify(context.currentUser)}</div>
      <div data-testid="current-user-roles">{JSON.stringify(context.currentUserRoles)}</div>
      <div data-testid="observed-user-id">{context.observedUserId || 'null'}</div>
    </div>
  )
}

describe('useWidgetDashboardContext', () => {
  it('should provide default values when no props are passed', () => {
    const {getByTestId} = render(
      <WidgetDashboardProvider>
        <TestConsumer />
      </WidgetDashboardProvider>,
    )

    expect(getByTestId('preferences')).toHaveTextContent(
      JSON.stringify({
        dashboard_view: 'cards',
        hide_dashcard_color_overlays: false,
        custom_colors: {},
        learner_dashboard_tab_selection: 'dashboard',
        widget_dashboard_config: {
          filters: {},
        },
      }),
    )
    expect(getByTestId('observed-users')).toHaveTextContent('[]')
    expect(getByTestId('can-add-observee')).toHaveTextContent('false')
    expect(getByTestId('current-user')).toHaveTextContent('null')
    expect(getByTestId('current-user-roles')).toHaveTextContent('[]')
    expect(getByTestId('observed-user-id')).toHaveTextContent('null')
  })

  it('should provide custom values when props are passed', () => {
    const preferences = {
      dashboard_view: 'list',
      hide_dashcard_color_overlays: true,
      custom_colors: {course1: '#ff0000'},
    }
    const observedUsersList = [
      {id: '1', name: 'Student 1', avatar_url: 'https://example.com/avatar1.jpg'},
      {id: '2', name: 'Student 2'},
    ]
    const currentUser = {
      id: '123',
      display_name: 'Observer User',
      avatar_image_url: 'https://example.com/observer.jpg',
    }
    const currentUserRoles = ['observer', 'user']

    const {getByTestId} = render(
      <WidgetDashboardProvider
        preferences={preferences}
        observedUsersList={observedUsersList}
        canAddObservee={true}
        currentUser={currentUser}
        currentUserRoles={currentUserRoles}
        observedUserId="123"
      >
        <TestConsumer />
      </WidgetDashboardProvider>,
    )

    expect(getByTestId('preferences')).toHaveTextContent(JSON.stringify(preferences))
    expect(getByTestId('observed-users')).toHaveTextContent(JSON.stringify(observedUsersList))
    expect(getByTestId('can-add-observee')).toHaveTextContent('true')
    expect(getByTestId('current-user')).toHaveTextContent(JSON.stringify(currentUser))
    expect(getByTestId('current-user-roles')).toHaveTextContent(JSON.stringify(currentUserRoles))
    expect(getByTestId('observed-user-id')).toHaveTextContent('123')
  })

  it('should memoize context value and not recreate when props are unchanged', () => {
    const contextValues: any[] = []
    const TestConsumerWithValueTracking: React.FC = () => {
      const context = useWidgetDashboard()
      contextValues.push(context)
      return <div data-testid="test-consumer">test</div>
    }

    const preferences = {
      dashboard_view: 'cards',
      hide_dashcard_color_overlays: false,
      custom_colors: {},
    }

    const {rerender} = render(
      <WidgetDashboardProvider preferences={preferences}>
        <TestConsumerWithValueTracking />
      </WidgetDashboardProvider>,
    )

    expect(contextValues).toHaveLength(1)

    // Re-render with same props - context value should be the same reference
    rerender(
      <WidgetDashboardProvider preferences={preferences}>
        <TestConsumerWithValueTracking />
      </WidgetDashboardProvider>,
    )

    expect(contextValues).toHaveLength(2)
    // Due to useMemo, the context object should be the same reference
    expect(contextValues[0]).toBe(contextValues[1])
  })

  it('should update context value when props change', () => {
    const initialPreferences = {
      dashboard_view: 'cards',
      hide_dashcard_color_overlays: false,
      custom_colors: {},
    }

    const updatedPreferences = {
      dashboard_view: 'list',
      hide_dashcard_color_overlays: true,
      custom_colors: {course1: '#blue'},
    }

    const {getByTestId, rerender} = render(
      <WidgetDashboardProvider preferences={initialPreferences}>
        <TestConsumer />
      </WidgetDashboardProvider>,
    )

    expect(getByTestId('preferences')).toHaveTextContent(JSON.stringify(initialPreferences))

    // Update props
    rerender(
      <WidgetDashboardProvider preferences={updatedPreferences}>
        <TestConsumer />
      </WidgetDashboardProvider>,
    )

    expect(getByTestId('preferences')).toHaveTextContent(JSON.stringify(updatedPreferences))
  })

  it('should handle null currentUser properly', () => {
    const {getByTestId} = render(
      <WidgetDashboardProvider currentUser={null}>
        <TestConsumer />
      </WidgetDashboardProvider>,
    )

    expect(getByTestId('current-user')).toHaveTextContent('null')
  })

  it('should handle undefined props by falling back to defaults', () => {
    const {getByTestId} = render(
      <WidgetDashboardProvider
        preferences={undefined}
        observedUsersList={undefined}
        canAddObservee={undefined}
        currentUser={undefined}
        currentUserRoles={undefined}
      >
        <TestConsumer />
      </WidgetDashboardProvider>,
    )

    expect(getByTestId('preferences')).toHaveTextContent(
      JSON.stringify({
        dashboard_view: 'cards',
        hide_dashcard_color_overlays: false,
        custom_colors: {},
        learner_dashboard_tab_selection: 'dashboard',
        widget_dashboard_config: {
          filters: {},
        },
      }),
    )
    expect(getByTestId('observed-users')).toHaveTextContent('[]')
    expect(getByTestId('can-add-observee')).toHaveTextContent('false')
    expect(getByTestId('current-user')).toHaveTextContent('null')
    expect(getByTestId('current-user-roles')).toHaveTextContent('[]')
  })
})
