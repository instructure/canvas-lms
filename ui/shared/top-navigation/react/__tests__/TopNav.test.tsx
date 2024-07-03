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

  afterEach(() => {
    window.ENV.breadcrumbs = []
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

  describe('getBreadCrumbSetter', () => {
    const callback = jest.fn()

    it('returns an object with getter and setter functions', () => {
      render(
        <QueryClientProvider client={queryClient}>
          <TopNav getBreadCrumbSetter={callback} />
        </QueryClientProvider>
      )

      expect(callback).toHaveBeenCalledWith({
        getCrumbs: expect.any(Function),
        setCrumbs: expect.any(Function),
      })
    })

    it('provides a getter function that actually returns the crumbs', () => {
      render(
        <QueryClientProvider client={queryClient}>
          <TopNav getBreadCrumbSetter={callback} />
        </QueryClientProvider>
      )

      const {getCrumbs} = callback.mock.calls[0][0]
      expect(getCrumbs()).toEqual(window.ENV.breadcrumbs)
    })

    // we need to figure out how to test this in the desktop layout mode
    // right now for some reason the Jest environment is triggering InstUI's
    // smallViewport layout, which doesn't show all the breadcrumbs. That
    // makes some of the stuff we want to test here meaningless.
    it.skip('provides a setter function that can set the last crumb', async () => {
      const {findByText} = render(
        <QueryClientProvider client={queryClient}>
          <TopNav getBreadCrumbSetter={callback} />
        </QueryClientProvider>
      )

      const {setCrumbs} = callback.mock.calls[0][0]
      setCrumbs({name: 'new-crumb2', url: 'new-crumb2'})

      expect(await findByText('new-crumb2')).toBeInTheDocument()
    })

    it.skip('provides a setter function that can set all crumbs', () => {})
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

  it('should not show a breadCrumb when there is one or less', () => {
    window.ENV.breadcrumbs = [{name: 'crumb', url: 'crumb'}]
    const {queryByText} = render(
      <QueryClientProvider client={queryClient}>
        <TopNav />
      </QueryClientProvider>
    )

    expect(queryByText('crumb')).not.toBeInTheDocument()
  })
})
