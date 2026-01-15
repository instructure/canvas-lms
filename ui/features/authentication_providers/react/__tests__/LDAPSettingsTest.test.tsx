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

import {render, screen, waitFor, within} from '@testing-library/react'
import LDAPSettingsTest from '../ldap/LDAPSettingsTest'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'

const server = setupServer()

describe('LDAPSettingsTest', () => {
  const queryClient = new QueryClient()
  const TEST_LDAP_CONNECTION_URL = '/accounts/1/test_ldap_connections'
  const TEST_LDAP_BIND_URL = '/accounts/1/test_ldap_binds'
  const TEST_LDAP_SEARCH_URL = '/accounts/1/test_ldap_searches'
  const TEST_LDAP_LOGIN_URL = '/accounts/1/test_ldap_logins'

  const renderModal = async () => {
    render(
      <MockedQueryClientProvider client={queryClient}>
        <LDAPSettingsTest accountId="1" ldapIps="192.0.0.1" />
      </MockedQueryClientProvider>,
    )

    const buttonText = screen.getByText('Test LDAP Authentication')
    await userEvent.click(buttonText.closest('button')!)
    await screen.findByLabelText('Test LDAP Settings')
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    const sharedProps = {
      account_authorization_config_id: '1',
      errors: [],
    }
    server.use(
      http.get(TEST_LDAP_CONNECTION_URL, () => {
        return HttpResponse.json([
          {
            ...sharedProps,
            ldap_connection_test: true,
          },
        ])
      }),
      http.get(TEST_LDAP_BIND_URL, () => {
        return HttpResponse.json([
          {
            ...sharedProps,
            ldap_bind_test: true,
          },
        ])
      }),
      http.get(TEST_LDAP_SEARCH_URL, () => {
        return HttpResponse.json([
          {
            ...sharedProps,
            ldap_search_test: true,
          },
        ])
      }),
      http.post(TEST_LDAP_LOGIN_URL, () => {
        return HttpResponse.json([
          {
            ...sharedProps,
            ldap_login_test: true,
          },
        ])
      }),
    )
    queryClient.clear()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('when testing connection', () => {
    describe('and the test failed', () => {
      it('should show the correct statuses and error info for the failed row', async () => {
        const connectionErrorFromResponse = 'Failed to connect to LDAP server'
        const connectionErrorDescription = "Canvas can't connect to your LDAP server"
        server.use(
          http.get(TEST_LDAP_CONNECTION_URL, () => {
            return HttpResponse.json([
              {
                account_authorization_config_id: '1',
                ldap_connection_test: false,
                errors: [{ldap_connection_test: connectionErrorFromResponse}],
              },
            ])
          }),
        )
        await renderModal()
        const testConnectionRow = screen.getByTestId('ldap-setting-test-connection')
        const testBindRow = screen.getByTestId('ldap-setting-test-bind')
        const testSearchRow = screen.getByTestId('ldap-setting-test-search')
        const testLoginRow = screen.getByTestId('ldap-setting-test-login')

        await waitFor(() => {
          expect(within(testConnectionRow).getByText('Failed')).toBeInTheDocument()
          expect(
            within(testConnectionRow).getByText(connectionErrorFromResponse),
          ).toBeInTheDocument()
          expect(
            within(testConnectionRow).getByText(connectionErrorDescription),
          ).toBeInTheDocument()
          expect(within(testBindRow).getByText('Canceled')).toBeInTheDocument()
          expect(within(testSearchRow).getByText('Canceled')).toBeInTheDocument()
          expect(within(testLoginRow).getByText('Canceled')).toBeInTheDocument()
        })
      })
    })
  })

  describe('when testing LDAP bind', () => {
    describe('and the test failed', () => {
      it('should show the correct statuses and error info for the failed row', async () => {
        const bindErrorFromResponse = 'Failed to bind to LDAP server'
        const bindErrorDescription = "Canvas can't bind (login) to your LDAP server"
        server.use(
          http.get(TEST_LDAP_BIND_URL, () => {
            return HttpResponse.json([
              {
                account_authorization_config_id: '1',
                ldap_bind_test: false,
                errors: [{ldap_bind_test: bindErrorFromResponse}],
              },
            ])
          }),
        )
        await renderModal()
        const testConnectionRow = screen.getByTestId('ldap-setting-test-connection')
        const testBindRow = screen.getByTestId('ldap-setting-test-bind')
        const testSearchRow = screen.getByTestId('ldap-setting-test-search')
        const testLoginRow = screen.getByTestId('ldap-setting-test-login')

        await waitFor(() => {
          expect(within(testConnectionRow).getByText('OK')).toBeInTheDocument()
          expect(within(testBindRow).getByText('Failed')).toBeInTheDocument()
          expect(within(testBindRow).getByText(bindErrorFromResponse)).toBeInTheDocument()
          expect(within(testBindRow).getByText(bindErrorDescription)).toBeInTheDocument()
          expect(within(testSearchRow).getByText('Canceled')).toBeInTheDocument()
          expect(within(testLoginRow).getByText('Canceled')).toBeInTheDocument()
        })
      })
    })
  })

  describe('when testing LDAP search', () => {
    describe('and the test failed', () => {
      it('should show the correct statuses and error info for the failed row', async () => {
        const searchErrorFromResponse = 'Failed to search LDAP server'
        const searchErrorDescription = "Canvas can't search your LDAP instance"
        server.use(
          http.get(TEST_LDAP_SEARCH_URL, () => {
            return HttpResponse.json([
              {
                account_authorization_config_id: '1',
                ldap_search_test: false,
                errors: [{ldap_search_test: searchErrorFromResponse}],
              },
            ])
          }),
        )
        await renderModal()
        const testConnectionRow = screen.getByTestId('ldap-setting-test-connection')
        const testBindRow = screen.getByTestId('ldap-setting-test-bind')
        const testSearchRow = screen.getByTestId('ldap-setting-test-search')
        const testLoginRow = screen.getByTestId('ldap-setting-test-login')

        await waitFor(() => {
          expect(within(testConnectionRow).getByText('OK')).toBeInTheDocument()
          expect(within(testBindRow).getByText('OK')).toBeInTheDocument()
          expect(within(testSearchRow).getByText('Failed')).toBeInTheDocument()
          expect(within(testSearchRow).getByText(searchErrorFromResponse)).toBeInTheDocument()
          expect(within(testSearchRow).getByText(searchErrorDescription)).toBeInTheDocument()
          expect(within(testLoginRow).getByText('Canceled')).toBeInTheDocument()
        })
      })
    })
  })

  describe('when testing user login', () => {
    describe('and every tests succeeded', () => {
      it('should show OK statuses and the test login form', async () => {
        await renderModal()
        const testConnectionRow = screen.getByTestId('ldap-setting-test-connection')
        const testBindRow = screen.getByTestId('ldap-setting-test-bind')
        const testSearchRow = screen.getByTestId('ldap-setting-test-search')
        const testLoginRow = screen.getByTestId('ldap-setting-test-login')

        await waitFor(() => {
          expect(within(testConnectionRow).getByText('OK')).toBeInTheDocument()
          expect(within(testBindRow).getByText('OK')).toBeInTheDocument()
          expect(within(testSearchRow).getByText('OK')).toBeInTheDocument()
          expect(
            within(testLoginRow).getByText('Supply a valid LDAP username/password to test login:'),
          ).toBeInTheDocument()
        })
      })
    })
  })
})
