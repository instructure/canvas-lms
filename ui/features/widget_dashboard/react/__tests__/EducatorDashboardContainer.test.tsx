/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import EducatorDashboardContainer from '../EducatorDashboardContainer'
import {WidgetDashboardProvider} from '../hooks/useWidgetDashboardContext'
import {WidgetDashboardEditProvider} from '../hooks/useWidgetDashboardEdit'
import {WidgetLayoutProvider} from '../hooks/useWidgetLayout'
import {ResponsiveProvider} from '../hooks/useResponsiveContext'
import {defaultGraphQLHandlers, clearWidgetDashboardCache, PlatformTestWrapper} from './testHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../components/DashboardTabs', () => ({
  default: () => <div data-testid="dashboard-tabs" />,
}))

vi.mock('../components/DashboardNotifications', () => ({
  default: () => <div data-testid="dashboard-notifications" />,
}))

const server = setupServer(
  ...defaultGraphQLHandlers,
  graphql.mutation('UpdateWidgetDashboardLayout', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateWidgetDashboardLayout: {
          layout: variables.layout,
          errors: null,
        },
      },
    })
  }),
)

const setup = (contextProps = {}) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return render(
    <PlatformTestWrapper>
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardProvider
          currentUser={{id: '123', display_name: 'Test Teacher', avatar_image_url: 'test.jpg'}}
          {...contextProps}
        >
          <WidgetDashboardEditProvider>
            <WidgetLayoutProvider>
              <ResponsiveProvider matches={['desktop']}>
                <EducatorDashboardContainer />
              </ResponsiveProvider>
            </WidgetLayoutProvider>
          </WidgetDashboardEditProvider>
        </WidgetDashboardProvider>
      </QueryClientProvider>
    </PlatformTestWrapper>,
  )
}

describe('EducatorDashboardContainer', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    fakeENV.setup({current_user_id: '123'})
    clearWidgetDashboardCache()
  })

  afterEach(() => {
    vi.restoreAllMocks()
    server.resetHandlers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  it('renders educator heading with greeting', () => {
    const {getByTestId} = setup()

    expect(getByTestId('educator-dashboard-heading')).toHaveTextContent('Hi, Test Teacher!')
  })

  it('shows Customize button', () => {
    const {getByTestId} = setup()

    expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
  })

  it('renders greeting without name when currentUser has no display_name', () => {
    const {getByTestId} = setup({
      currentUser: {id: '123', display_name: '', avatar_image_url: ''},
    })

    expect(getByTestId('educator-dashboard-heading')).toHaveTextContent('Hi!')
  })

  it('enters edit mode when customize button is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = setup()

    await user.click(getByTestId('customize-dashboard-button'))

    await waitFor(() => {
      expect(queryByTestId('customize-dashboard-button')).not.toBeInTheDocument()
      expect(getByTestId('save-customize-button')).toBeInTheDocument()
      expect(getByTestId('cancel-customize-button')).toBeInTheDocument()
    })
  })

  it('exits edit mode when cancel button is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = setup()

    await user.click(getByTestId('customize-dashboard-button'))
    expect(getByTestId('cancel-customize-button')).toBeInTheDocument()

    await user.click(getByTestId('cancel-customize-button'))

    await waitFor(() => {
      expect(queryByTestId('cancel-customize-button')).not.toBeInTheDocument()
      expect(queryByTestId('save-customize-button')).not.toBeInTheDocument()
      expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
    })
  })

  it('renders DashboardTabs', () => {
    const {getByTestId} = setup()

    expect(getByTestId('dashboard-tabs')).toBeInTheDocument()
  })

  it('saves layout and exits edit mode on save', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = setup()

    await user.click(getByTestId('customize-dashboard-button'))
    await user.click(getByTestId('save-customize-button'))

    await waitFor(() => {
      expect(queryByTestId('save-customize-button')).not.toBeInTheDocument()
      expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
    })
  })

  it('displays error alert when save fails', async () => {
    const user = userEvent.setup()
    vi.spyOn(console, 'error').mockImplementation(() => {})

    server.use(
      graphql.mutation('UpdateWidgetDashboardLayout', () => {
        return HttpResponse.json({
          data: {
            updateWidgetDashboardLayout: {
              layout: null,
              errors: [{message: 'Invalid widget configuration'}],
            },
          },
        })
      }),
    )

    const {getByTestId, findByText} = setup()

    await user.click(getByTestId('customize-dashboard-button'))
    await user.click(getByTestId('save-customize-button'))

    const errorAlert = await findByText(/Invalid widget configuration/i)
    expect(errorAlert).toBeInTheDocument()
  })
})
