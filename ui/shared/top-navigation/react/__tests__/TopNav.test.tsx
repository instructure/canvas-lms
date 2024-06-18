// Copyright (C) 2023 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along

import {render} from '@testing-library/react'
import TopNav from '../TopNav'
import React from 'react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {TopNavBar} from '@instructure/ui-top-nav-bar'

// with this program. If not, see <http://www.gnu.org/licenses/>.
const queryClient = new QueryClient()

jest.mock('../hooks/useToggleCourseNav', () => ({
  __esModule: true,
  default: () => ({
    toggle: jest.fn(),
  }),
}))
describe('TopNav', () => {
  // test that TopNav renders without errors
  beforeEach(() => {
    window.ENV.breadcrumbs = [
      {name: 'crumb', url: 'crumb'},
      {name: 'crumb2', url: 'crumb2'},
    ]
  })

  it('renders', () => {
    expect(() =>
      render(
        <QueryClientProvider client={queryClient}>
          <TopNav />
        </QueryClientProvider>
      )
    ).not.toThrow()
  })

  it('renders with breadcrumbs', () => {
    const {getByText} = render(
      <QueryClientProvider client={queryClient}>
        <TopNav />
      </QueryClientProvider>
    )

    expect(getByText('crumb')).toBeInTheDocument()
  })
  it('shows action buttons when sent through prop', () => {
    const {getByText} = render(
      <QueryClientProvider client={queryClient}>
        <TopNav
          actionItems={[
            <TopNavBar.Item id="button1" key="button1">
              button1
            </TopNavBar.Item>,
            <TopNavBar.Item id="button2" key="button2">
              button2
            </TopNavBar.Item>,
          ]}
        />
      </QueryClientProvider>
    )

    expect(getByText('button1')).toBeInTheDocument()
    expect(getByText('button2')).toBeInTheDocument()
  })
})
