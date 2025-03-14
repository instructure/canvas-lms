/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {AppsTableInner} from '../AppsTable'
import {mockPageOfRegistrations, mockRegistration} from './helpers'
import {BrowserRouter} from 'react-router-dom'

// Need to use AppsTableInner because AppsTable uses Responsive
// which doesn't seem to work in these tests -- both media queries are
// satisfied and the component gets two "layout" properties
describe('AppsTableInner', () => {
  it('calls the deleteApp callback when the Delete App menu item is clicked', async () => {
    const deleteApp = jest.fn()
    const wrapper = render(
      <BrowserRouter>
        <AppsTableInner
          tableProps={{
            apps: mockPageOfRegistrations('Hello', 'World'),
            dir: 'asc',
            sort: 'name',
            updateSearchParams: () => {},
            deleteApp,
            page: 1,
          }}
          responsiveProps={undefined}
        />
      </BrowserRouter>,
    )

    const kebabMenuIcon = await wrapper.findAllByText('More Registration Options')
    fireEvent.click(kebabMenuIcon[0])
    const deleteButton = await wrapper.findByText('Delete App')

    expect(deleteApp).not.toHaveBeenCalled()
    fireEvent.click(deleteButton)
    expect(deleteApp).toHaveBeenCalled()
  })

  it('shows the current page and total count', async () => {
    const wrapper = render(
      <BrowserRouter>
        <AppsTableInner
          tableProps={{
            apps: mockPageOfRegistrations(
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
              '10',
              '11',
              '12',
              '13',
              '14',
              '15',
              '16',
              '17',
            ),
            dir: 'asc',
            sort: 'name',
            updateSearchParams: () => {},
            deleteApp: () => {},
            page: 2,
          }}
          responsiveProps={undefined}
        />
      </BrowserRouter>,
    )
    await waitFor(() => {
      expect(wrapper.getByText('16 - 17 of 17 displayed')).toBeInTheDocument()
    })
  })

  it('renders the both the updated at and created at columns with the correct format', async () => {
    const registrations = mockPageOfRegistrations('Hello', 'World')
    registrations.data[0].created_at = new Date('2024-01-01T00:00:00Z')
    registrations.data[0].updated_at = new Date('2024-01-01T00:00:00Z')
    registrations.data[1].created_at = new Date('2024-01-02T00:00:00Z')
    registrations.data[1].updated_at = new Date('2024-01-02T00:00:00Z')
    render(
      <BrowserRouter>
        <AppsTableInner
          tableProps={{
            apps: registrations,
            dir: 'asc',
            sort: 'name',
            updateSearchParams: () => {},
            deleteApp: () => {},
            page: 1,
          }}
          responsiveProps={undefined}
        />
      </BrowserRouter>,
    )

    expect(screen.getAllByText('Jan 1, 2024')).toHaveLength(2)
    expect(screen.getAllByText('Jan 2, 2024')).toHaveLength(2)
  })

  it('does not show the edit button for inherited registrations', async () => {
    const wrapper = render(
      <BrowserRouter>
        <AppsTableInner
          tableProps={{
            apps: {
              data: [mockRegistration('ExampleApp', 1, {}, {inherited: true})],
              total: 1,
            },
            dir: 'asc',
            sort: 'name',
            updateSearchParams: () => {},
            deleteApp: () => {},
            page: 1,
          }}
          responsiveProps={undefined}
        />
      </BrowserRouter>,
    )

    expect(wrapper.getByTestId(`actions-menu-1`)).toBeInTheDocument()
    wrapper.getByTestId(`actions-menu-1`).click()
    expect(wrapper.queryByText('Edit App')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Copy Client ID')).toBeInTheDocument()
  })

  it('shows the created by and updated by fields as Instructure for site admin registrations', async () => {
    const wrapper = render(
      <BrowserRouter>
        <AppsTableInner
          tableProps={{
            apps: {
              data: [
                mockRegistration(
                  'ExampleApp',
                  1,
                  {},
                  {created_by: 'Instructure', updated_by: 'Instructure'},
                ),
              ],
              total: 1,
            },
            dir: 'asc',
            sort: 'name',
            updateSearchParams: () => {},
            deleteApp: () => {},
            page: 1,
          }}
          responsiveProps={undefined}
        />
      </BrowserRouter>,
    )

    expect(wrapper.getAllByText('Instructure')).toHaveLength(2)
  })

  it("renders a link to the tool's detail page", async () => {
    window.ENV.FEATURES.lti_registrations_next = true
    const wrapper = render(
      <BrowserRouter>
        <AppsTableInner
          tableProps={{
            apps: {
              data: [
                mockRegistration(
                  'ExampleApp',
                  1,
                  {},
                  {created_by: 'Instructure', updated_by: 'Instructure'},
                ),
              ],
              total: 1,
            },
            dir: 'asc',
            sort: 'name',
            updateSearchParams: () => {},
            deleteApp: () => {},
            page: 1,
          }}
          responsiveProps={undefined}
        />
      </BrowserRouter>,
    )

    const link = wrapper.getByTestId('reg-link-1')
    expect(link).toHaveAttribute('href', '/manage/1/configuration')
    window.ENV.FEATURES.lti_registrations_next = false
  })
})
