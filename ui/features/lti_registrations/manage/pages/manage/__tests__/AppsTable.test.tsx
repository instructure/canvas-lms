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

import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {type MockedFunction} from 'vitest'
import {AppsTableInner, type AppsTableInnerProps} from '../AppsTable'
import {mockPageOfRegistrations, mockRegistration, mswHandlers} from './helpers'
import {BrowserRouter} from 'react-router-dom'
import {ZAccountId} from '../../../model/AccountId'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

vi.mock('@canvas/alerts/react/FlashAlert')

const mockFlash = showFlashAlert as MockedFunction<typeof showFlashAlert>

const server = setupServer(...mswHandlers)
// Need to use AppsTableInner because AppsTable uses Responsive
// which doesn't seem to work in these tests -- both media queries are
// satisfied and the component gets two "layout" properties
describe('AppsTableInner', () => {
  beforeEach(() => {
    server.listen()
    fakeENV.setup({
      FEATURES: {
        lti_registrations_next: false,
      },
    })
    // Create flash_screenreader_holder element for Alert components
    const flashHolder = document.createElement('div')
    flashHolder.id = 'flash_screenreader_holder'
    flashHolder.setAttribute('role', 'alert')
    document.body.appendChild(flashHolder)
  })

  afterEach(() => {
    server.resetHandlers()
    server.close()
    fakeENV.teardown()
    // Clean up any flash_screenreader_holder elements
    const flashHolder = document.getElementById('flash_screenreader_holder')
    if (flashHolder) {
      document.body.removeChild(flashHolder)
    }
  })

  type PropsOverrides = {
    [key in keyof AppsTableInnerProps]?: Partial<AppsTableInnerProps[key]>
  }

  const renderTable = (overrides: PropsOverrides = {}) => {
    return render(
      <BrowserRouter>
        <QueryClientProvider
          client={
            new QueryClient({
              defaultOptions: {
                queries: {
                  retry: false,
                  refetchOnWindowFocus: false,
                },
              },
            })
          }
        >
          <AppsTableInner
            tableProps={{
              apps: mockPageOfRegistrations('Hello', 'World'),
              dir: 'asc',
              sort: 'name',
              updateSearchParams: () => {},
              page: 1,
              accountId: ZAccountId.parse('1'),
              ...overrides.tableProps,
            }}
            responsiveProps={{
              ...overrides.responsiveProps,
            }}
          />
        </QueryClientProvider>
      </BrowserRouter>,
    )
  }

  it('deletes the app when the Delete App menu item is clicked', async () => {
    const wrapper = renderTable()

    const kebabMenuIcon = await wrapper.findAllByText('More Registration Options', {exact: false})
    fireEvent.click(kebabMenuIcon[0])
    const deleteButton = await wrapper.findByText('Delete App')

    fireEvent.click(deleteButton)

    const confirmDeleteButton = await wrapper.findByRole('button', {
      name: /delete/i,
    })
    fireEvent.click(confirmDeleteButton)

    await waitFor(() => {
      expect(mockFlash).toHaveBeenCalledWith({
        type: 'success',
        message: expect.stringContaining('deleted'),
      })
    })
  })

  it('shows the current page and total count', async () => {
    const wrapper = renderTable({
      tableProps: {
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
        page: 2,
      },
    })
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
    renderTable({
      tableProps: {
        apps: registrations,
      },
    })

    expect(screen.getAllByText('Jan 1, 2024')).toHaveLength(2)
    expect(screen.getAllByText('Jan 2, 2024')).toHaveLength(2)
  })

  it('does not show the edit button for inherited registrations', async () => {
    const wrapper = renderTable({
      tableProps: {
        apps: {
          data: [mockRegistration('ExampleApp', 1, {}, {inherited: true})],
          total: 1,
        },
      },
    })

    expect(wrapper.getByTestId(`actions-menu-1`)).toBeInTheDocument()
    wrapper.getByTestId(`actions-menu-1`).click()
    expect(wrapper.queryByText('Edit App')).not.toBeInTheDocument()
    expect(wrapper.queryByText('Copy Client ID')).toBeInTheDocument()
  })

  it('shows the created by and updated by fields as Instructure for site admin registrations', async () => {
    const wrapper = renderTable({
      tableProps: {
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
      },
    })

    expect(wrapper.getAllByText('Instructure')).toHaveLength(2)
  })

  describe('with flag on', () => {
    beforeEach(() => {
      window.ENV.FEATURES.lti_registrations_next = true
    })

    it("renders a link to the tool's detail page", async () => {
      const wrapper = renderTable({
        tableProps: {
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
        },
      })

      const link = wrapper.getByTestId('reg-link-1')
      expect(link).toHaveAttribute('href', '/manage/1')
    })

    it('displays the appropriate columns', async () => {
      const wrapper = renderTable({
        tableProps: {
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
        },
      })

      const columns = wrapper.getAllByRole('columnheader')
      expect(columns).toHaveLength(6)
      expect(columns[0]).toHaveTextContent('Name')
      expect(columns[1]).toHaveTextContent('Nickname')
      expect(columns[2]).toHaveTextContent('Installed On')
      expect(columns[3]).toHaveTextContent('Version')
      expect(columns[4]).toHaveTextContent('On/Off')
      expect(columns[5]).toHaveTextContent('Status')
    })

    it('shows condensed version of table', async () => {
      const wrapper = renderTable({
        tableProps: {
          apps: mockPageOfRegistrations('Hello', 'World'),
        },
      })

      const kebabMenuIcons = wrapper.queryAllByText('More Registration Options', {
        exact: false,
      })
      expect(kebabMenuIcons).toHaveLength(0)
    })
  })
})
